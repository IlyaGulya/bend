/** Generic generated Control runtime. Effect ownership follows invocation boundaries,
 * independently of semantic cursors, results, or continuation payloads. */
import { term_lower, term_show, type Body, type LTerm, type Patt } from "../bend2/bend.ts";
import type { ParserGraph, ParserParameter } from "./parser_full_graph.ts";
import { freeBinderIds, LexicalTypes } from "./parser_full_type_env.ts";
export type ExplicitControlRuntimeConfig = {
  frameVariants: readonly string[];
  requestVariants: readonly string[];
  dispatchCases: readonly string[];
  resumeCases: readonly string[];
};

export function renderExplicitControlRuntime(config: ExplicitControlRuntimeConfig): {
  typeDeclarations: string[];
  declarations: Map<string, string>;
} {
  const typeDeclarations = [
    "type Progress is Data:\n  NoProgress{}\n  Consumed{}",
    "type FeedbackCursorWitness is Data:\n  WitnessNone{}\n  WitnessTail{progress: Progress}\n  WitnessFields{fields: List<&2, FeedbackCursorWitness>}",
    ["type FeedbackFrame is Data:", "  KontProgress{}", ...config.frameVariants].join("\n"),
    "type FeedbackKont is Data:\n  FeedbackKont{frame: FeedbackFrame, progress: Progress}",
    ["type FeedbackRequest is Data:", ...config.requestVariants].join("\n"),
    "type FeedbackAction is Data:\n  FeedbackCall{request: FeedbackRequest}\n  FeedbackDone{value: FeedbackValue}\n  FeedbackInvariant{}",
    "type FeedbackControl is Data:\n  FeedbackControl{action: FeedbackAction, pending: List<&2, FeedbackKont>, progress: Progress, own_progress: Progress}",
    "type FeedbackResume is Data:\n  FeedbackResume{control: FeedbackControl, progress: Progress, own_progress: Progress}",
    "type FeedbackFuel is Data:\n  FeedbackFuelEnd{}\n  FeedbackFuelCell{tail: FeedbackFuel}",
    "type FeedbackRun is Data:\n  FeedbackComplete{value: FeedbackValue, progress: Progress}\n  FeedbackInvariantFailure{progress: Progress}",
  ];
  const declarations = new Map<string, string>();
  function add(name: string, body: string): void { declarations.set(name, body); }
  add("feedback_compose_progress", `def feedback_compose_progress(left: Progress, right: Progress) -> Progress:
  match left:
    case NoProgress{}: right
    case Consumed{}: Consumed{}`);
  // The saved effect is a caller-owned frame, not an annotation on a child's
  // active Control or its frames. This also handles opaque semantic remainders.
  add("feedback_save_progress", `def feedback_save_progress(progress: Progress, pending: List<&2, FeedbackKont>) -> List<&2, FeedbackKont>:
  match progress:
    case NoProgress{}: pending
    case Consumed{}:
      List.append(&2, FeedbackKont, pending, FeedbackKont{KontProgress{}, Consumed{}} <> Nil{})`);
  add("feedback_prefix", `def feedback_prefix(before: Progress, control: FeedbackControl) -> FeedbackControl:
  match before:
    case NoProgress{}: control
    case Consumed{}: feedback_prefix_consumed(Consumed{}, control)`);
  add("feedback_prefix_inherited", `def feedback_prefix_inherited(before: Progress, control: FeedbackControl) -> FeedbackControl:
  match before:
    case NoProgress{}: control
    case Consumed{}: feedback_prefix_consumed(NoProgress{}, control)`);
  add("feedback_prefix_consumed", `def feedback_prefix_consumed(fresh: Progress, control: FeedbackControl) -> FeedbackControl:
  match control:
    case FeedbackControl{action, pending, progress, own_progress}:
      match action:
        case FeedbackDone{value}:
          match pending:
            case Nil{}:
              FeedbackControl{FeedbackDone{value}, Nil{}, feedback_compose_progress(Consumed{}, progress), feedback_compose_progress(fresh, own_progress)}
            case frame <> tail:
              FeedbackControl{FeedbackDone{value}, feedback_save_progress(Consumed{}, frame <> tail), progress, feedback_compose_progress(fresh, own_progress)}
        case FeedbackCall{request}:
          FeedbackControl{FeedbackCall{request}, feedback_save_progress(Consumed{}, pending), progress, feedback_compose_progress(fresh, own_progress)}
        case FeedbackInvariant{}:
          FeedbackControl{FeedbackInvariant{}, pending, feedback_compose_progress(Consumed{}, progress), feedback_compose_progress(fresh, own_progress)}`);
  add("feedback_attach", `def feedback_attach(step: FeedbackControl, frame: FeedbackFrame) -> FeedbackControl:
  feedback_attach_with_progress(NoProgress{}, step, frame)`);
  add("feedback_attach_with_progress", `def feedback_attach_with_progress(+before: Progress, step: FeedbackControl, frame: FeedbackFrame) -> FeedbackControl:
  match step:
    case FeedbackControl{action, pending, progress, own_progress}:
      FeedbackControl{action, List.append(&2, FeedbackKont, pending, FeedbackKont{frame, before} <> Nil{}), progress, feedback_compose_progress(before, own_progress)}`);
  add("feedback_dispatch", ["def feedback_dispatch(request: FeedbackRequest) -> FeedbackControl:", "  match request:", ...config.dispatchCases].join("\n"));
  add("feedback_resume_frame", ["def feedback_resume_frame(frame: FeedbackFrame, value: FeedbackValue) -> FeedbackControl:", "  match frame:", "    case KontProgress{}: FeedbackControl{FeedbackDone{value}, Nil{}, NoProgress{}, NoProgress{}}", ...config.resumeCases].join("\n"));
  add("feedback_resume", `def feedback_resume(saved: FeedbackKont, value: FeedbackValue, child_progress: Progress) -> FeedbackResume:
  match saved:
    case FeedbackKont{frame, progress}:
      feedback_pack_resume(feedback_compose_progress(progress, child_progress), feedback_resume_frame(frame, value))`);
  add("feedback_pack_resume", `def feedback_pack_resume(+segment_progress: Progress, +control: FeedbackControl) -> FeedbackResume:
  match control:
    case FeedbackControl{_, _, _, own_progress}:
      FeedbackResume{feedback_prefix_inherited(segment_progress, control), segment_progress, own_progress}`);
  add("feedback_use_resume", `def feedback_use_resume(resumed: FeedbackResume, use: FeedbackControl -> FeedbackRun) -> FeedbackRun:
  match resumed:
    case FeedbackResume{control, _, _}:
      use(control)`);
  add("feedback_stack_progress", `def feedback_stack_progress(stack: List<&2, FeedbackKont>) -> Progress:
  match stack:
    case Nil{}: NoProgress{}
    case FeedbackKont{_, progress} <> tail:
      feedback_compose_progress(progress, feedback_stack_progress(tail))`);
  add("feedback_failure", `def feedback_failure(progress: Progress, pending: List<&2, FeedbackKont>, stack: List<&2, FeedbackKont>) -> FeedbackRun:
  FeedbackInvariantFailure{feedback_compose_progress(progress, feedback_compose_progress(feedback_stack_progress(pending), feedback_stack_progress(stack)))}`);
  add("feedback_finish", `def feedback_finish(step: FeedbackControl, stack: List<&2, FeedbackKont>) -> FeedbackRun:
  match step:
    case FeedbackControl{action, pending, progress, _}:
      match action:
        case FeedbackDone{value}:
          match pending:
            case Nil{}:
              match stack:
                case Nil{}: FeedbackComplete{value, progress}
                case frame <> tail: feedback_failure(progress, Nil{}, frame <> tail)
            case frame <> tail: feedback_failure(progress, frame <> tail, stack)
        case _: feedback_failure(progress, pending, stack)`);
  add("feedback_drive", `def feedback_drive(fuel: FeedbackFuel, step: FeedbackControl, stack: List<&2, FeedbackKont>) -> FeedbackRun:
  match fuel:
    case FeedbackFuelEnd{}: feedback_finish(step, stack)
    case FeedbackFuelCell{remaining}:
      match step:
        case FeedbackControl{action, pending, progress, _}:
          match action:
            case FeedbackInvariant{}:
              feedback_failure(progress, pending, stack)
            case FeedbackCall{request}:
              feedback_drive(remaining, feedback_dispatch(request), List.append(&2, FeedbackKont, feedback_save_progress(progress, pending), stack))
            case FeedbackDone{value}:
              match pending:
                case frame <> tail:
                  feedback_use_resume(feedback_resume(frame, value, progress), control => feedback_drive(remaining, control, List.append(&2, FeedbackKont, tail, stack)))
                case Nil{}:
                  match stack:
                    case frame <> tail:
                      feedback_use_resume(feedback_resume(frame, value, progress), control => feedback_drive(remaining, control, tail))
                    case Nil{}: FeedbackComplete{value, progress}`);
  return {typeDeclarations, declarations};
}

export type StructuralFeedbackFuelProgram = {
  declarations: Map<string, string>;
  tokenCellDefinition: string;
  chunkCells: number;
};

/** Emit the certificate's literal chunk and a typed projection of actual initial
 * cursor cells. Every empty cursor is identity; the final chunk is added once. */
export function renderStructuralFeedbackFuel(graph: ParserGraph, height: number, tokenElement = "lexer.Token"): StructuralFeedbackFuelProgram {
  if (!Number.isSafeInteger(height) || height < 0) throw Error("Structural fuel requires a certified nonnegative finite H");
  const lexical = new LexicalTypes(graph.parserBook, graph.signatures);
  const probeSpan = {src:graph.source, beg:0, end:0};
  function normalize(type: LTerm) {
    const probe: LTerm = {$:"Var", k:"probe", i:-1};
    lexical.indexBody({$:"Reply", x:probe}, [[{$:"Many"}, "probe", -1, type, probeSpan]], type);
    return lexical.typeOf(probe);
  }
  function constructorFields(type: Extract<LTerm, {$:"ADT"}>, constructor: string) {
    const declaration = graph.parserBook.tlds[type.k], definition = graph.parserBook.ctrs[constructor];
    if (declaration?.$ !== "ADT" || !definition) throw Error("Unknown structural fuel datatype constructor: " + constructor);
    let telescope = term_lower(definition.T);
    for(let index=0;index<declaration.n;index++){
      if(telescope.$ !== "All")throw Error("Invalid structural fuel datatype parameter telescope: " + constructor);
      telescope=telescope.B;
    }
    const patterns: Patt[] = [];
    while(telescope.$ === "All"){
      patterns.push({$:"PVar",k:"field_"+patterns.length,i:-2-patterns.length,q:{$:"Lone"}});
      telescope=telescope.B;
    }
    const probe: LTerm = {$:"Var",k:"probe",i:-1};
    const body: Body = {$:"Match",e:[probe],r:[{p:[{$:"PCtr",k:constructor,x:patterns}],f:{$:"Reply",x:probe}}]};
    const parameters: ParserParameter[] = [[{$:"Many"},"probe",-1,type,probeSpan]];
    lexical.indexBody(body,parameters,type);
    const environment=lexical.environmentAt(probe);
    return patterns.map((_,index)=>{
      const field=environment.get(-2-index);
      if(!field)throw Error("Missing structurally projected fuel field: " + constructor);
      return field.type;
    });
  }
  type Projection = {type:LTerm;name:string;tokenList:boolean;containsCursor:boolean;constructors:{name:string;fields:Projection[]}[]};
  const projections=new Map<string,Projection>();
  function discover(input:LTerm):Projection {
    const type=normalize(input),key=term_show(type),existing=projections.get(key);
    if(existing)return existing;
    if(freeBinderIds(type).length)throw Error("Dependent cursor projection cannot be emitted as a closed fuel helper: " + key);
    if(type.$==="All")throw Error("An opaque function-valued initial payload cannot be projected into structural token fuel");
    const tokenList=type.$==="ADT"&&type.k==="List"&&type.x.some(element=>(element.$==="ADT"||element.$==="Ref")&&element.k===tokenElement);
    const projection:Projection={type,name:"feedback_project_fuel_"+projections.size,tokenList,containsCursor:tokenList,constructors:[]};
    projections.set(key,projection);
    if(type.$==="ADT"&&!tokenList){
      const datatype=graph.parserBook.tlds[type.k];
      if(datatype?.$!=="ADT")throw Error("Missing structural fuel datatype: " + type.k);
      projection.constructors=datatype.c.map(constructor=>({name:constructor.k,fields:constructorFields(type,constructor.k).map(discover)}));
    }
    return projection;
  }
  const controlType=graph.signatures.get("feedback_drive")?.parameters[1]?.[3];
  if(!controlType)throw Error("Structural fuel has no typed initial Control parameter");
  const root=discover(controlType);
  for(let changed=true;changed;){
    changed=false;
    for(const projection of projections.values())if(!projection.containsCursor&&projection.constructors.some(constructor=>constructor.fields.some(field=>field.containsCursor))){
      projection.containsCursor=true;changed=true;
    }
  }
  const declarations=new Map<string,string>();
  let chunk="tail";
  for(let index=0;index<=height;index++)chunk="FeedbackFuelCell{"+chunk+"}";
  declarations.set("feedback_fuel_chunk","def feedback_fuel_chunk(tail: FeedbackFuel) -> FeedbackFuel:\n  "+chunk);
  for(const projection of projections.values()){
    if(!projection.containsCursor)continue;
    const header="def "+projection.name+"(+value: "+term_show(projection.type)+", tail: FeedbackFuel) -> FeedbackFuel:\n";
    if(projection.tokenList){
      declarations.set(projection.name,header+"  match value:\n    case Nil{}: tail\n    case _ <> +rest:\n      feedback_fuel_chunk("+projection.name+"(rest, tail))");
      continue;
    }
    declarations.set(projection.name,header+"  match value:\n"+projection.constructors.map(constructor=>{
      const fields=constructor.fields.map((field,index)=>field.containsCursor?"+field_"+index:"_");
      let fuel="tail";
      for(let index=constructor.fields.length-1;index>=0;index--){
        const field=constructor.fields[index]!;
        if(field.containsCursor)fuel=field.name+"(field_"+index+", "+fuel+")";
      }
      return "    case "+constructor.name+"{"+fields.join(", ")+"}:\n      "+fuel;
    }).join("\n"));
  }
  const initialFuel=root.containsCursor?root.name+"(initial, feedback_fuel_chunk(FeedbackFuelEnd{}))":"feedback_fuel_chunk(FeedbackFuelEnd{})";
  declarations.set("feedback_start",`def feedback_start(+initial: FeedbackControl) -> FeedbackRun:
  match initial:
    case FeedbackControl{FeedbackDone{value}, Nil{}, progress, _}:
      FeedbackComplete{value, progress}
    case _:
      feedback_drive(${initialFuel}, initial, Nil{})`);
  return {declarations, tokenCellDefinition:"N is the sum of token-list cells structurally projected from the initial FeedbackControl Request, pending Frame, and Value payloads; duplicate captured cursors are counted separately.",chunkCells:height+1};
}
