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
open Compiler.EnhancedCompiler

type serialization_format =
  | META
  | ENHANCED

(* Data utils for the Camp evaluator and compiler *)

type io_hierarchy = QData.json
type io_json = QData.json option

type io_hierarchy_list = (string * string) list
type io_input = QData.data list
type io_partitioned_input = ((char list) * QData.data) list
type io_output = QData.data list

type rtype_content = QData.json
type json_schema = (io_hierarchy_list * QData.json * QData.json) option
type model_content = string * (string * string) list * (string * rtype_content) list

val get_io_content : io_json -> QData.json * QData.json * QData.json * QData.json * QData.json * QData.json
val get_hierarchy : io_json -> io_hierarchy
val get_hierarchy_cloudant : io_json -> io_hierarchy
val build_hierarchy : io_hierarchy -> io_hierarchy_list
val get_input : serialization_format -> io_json -> io_input
val get_partitioned_input : serialization_format -> io_json -> io_partitioned_input
val get_output : io_json -> io_output

val get_model_content : QData.json -> model_content

val display_sdata : string option -> string -> string list -> string -> unit
