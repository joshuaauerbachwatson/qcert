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

open Compiler.EnhancedCompiler

type global_config = {
    mutable gconf_source : QLang.language;
    mutable gconf_target : QLang.language;
    mutable gconf_path : QLang.language list; (* the first element of the path must be source and the last target *)
    mutable gconf_exact_path : bool;
    mutable gconf_dir : string option;
    mutable gconf_dir_target : string option;
    mutable gconf_io : string option;
    mutable gconf_io_use_world : bool;
    mutable gconf_schema : TypeUtil.schema;
    mutable gconf_data : QEval.eval_input;
    mutable gconf_expected_output_data : DataUtil.io_output;
    gconf_cld_conf : CloudantUtil.cld_config;
    mutable gconf_emit_all : bool;
    gconf_pretty_config : PrettyIL.pretty_config;
    mutable gconf_emit_sexp : bool;
    mutable gconf_emit_sexp_all : bool;
    mutable gconf_eval : bool;
    mutable gconf_eval_all : bool;
    mutable gconf_eval_debug : bool;
    mutable gconf_eval_validate : bool;
    mutable gconf_source_sexp : bool;
    mutable gconf_java_imports : string;
    mutable gconf_mr_vinit : string;
    mutable gconf_vdbindings : QLang.vdbindings;
    mutable gconf_stat : bool;
    mutable gconf_stat_all : bool;
    mutable gconf_stat_tree : bool;
  }

val complet_configuration : global_config -> global_config

val driver_conf_of_global_conf : global_config -> string -> string -> QDriver.driver_config
