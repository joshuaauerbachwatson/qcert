(*
 * Copyright 2015-2016 IBM Corporation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *)

open Util
open QcertUtil
open QcertConfig
open Compiler.EnhancedCompiler


let set_source gconf s = gconf.gconf_source <- language_of_name s
let set_target gconf s = gconf.gconf_target <- language_of_name s
let add_path gconf s = gconf.gconf_path <- gconf.gconf_path @ [ language_of_name s ]
let set_exact_path gconf () = gconf.gconf_exact_path <- true
let set_dir gconf s = gconf.gconf_dir <- Some s
let set_dir_target gconf s = gconf.gconf_dir_target <- Some s
let set_io gconf file_name = gconf.gconf_io <- Some (Util.string_of_file file_name)
let set_emit_all gconf () = gconf.gconf_emit_all <- true
let set_emit_sexp gconf () = gconf.gconf_emit_sexp <- true
let set_emit_sexp_all gconf () = gconf.gconf_emit_sexp_all <- true
let set_eval gconf () = gconf.gconf_eval <- true
let set_eval_all gconf () = gconf.gconf_eval_all <- true
let set_eval_debug gconf () = gconf.gconf_eval_debug <- true
let set_eval_validate gconf () = gconf.gconf_eval_validate <- true
let set_source_sexp gconf () = gconf.gconf_source_sexp <- true
let set_java_imports gconf s = gconf.gconf_java_imports <- s
let set_vinit gconf x = gconf.gconf_mr_vinit <- x
let add_vdirst gconf x =
  let x = char_list_of_string x in
  gconf.gconf_vdbindings <- (x, Compiler.Vdistr) :: gconf.gconf_vdbindings
let set_io_use_world gconf () = gconf.gconf_io_use_world <- true; add_vdirst gconf "CONST$WORLD" (* XXX HACK TO BE REVIEWED XXX *)
let add_vlocal gconf x =
  let x = char_list_of_string x in
  gconf.gconf_vdbindings <- (x, Compiler.Vlocal) :: gconf.gconf_vdbindings
let set_stat gconf () = gconf.gconf_stat <- true
let set_stat_all gconf () = gconf.gconf_stat_all <- true
let set_stat_tree gconf () = gconf.gconf_stat_tree <- true
