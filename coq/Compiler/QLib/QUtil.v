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

Require Import CompilerRuntime.
Module QUtil(runtime:CompilerRuntime).

  Require Import BasicRuntime NNRCMRRuntime.
  Require Import TDNRCInfer.
  
  (* mr_reduce_empty isn't a field of mr so it needs to be exposed *)
  Definition mr_reduce_empty := mr_reduce_empty.

  (* Access to type annotations *)
  Definition type_annotation {br:brand_relation} (A:Set): Set
    := TDNRCInfer.type_annotation A.

  Definition ta_base {br:brand_relation} (A:Set) (ta:type_annotation A)
    := TDNRCInfer.ta_base ta.
  Definition ta_inferred {br:brand_relation} (A:Set) (ta:type_annotation A)
    := TDNRCInfer.ta_inferred ta .
  Definition ta_required {br:brand_relation} (A:Set) (ta:type_annotation A)
    := TDNRCInfer.ta_required ta.

  (* Processing for input or output of queries *)
  Require Import CompEnv.
  Definition validate_lifted_success := validate_lifted_success.

  Definition mkDistLoc := mkConstants mkDistLoc. (* XXX Where should mkConstants be? *)
  Definition mkDistWorld env := mkConstants (mkDistWorld env). (* XXX Where should mkConstants be? *)
End QUtil.

(*
*** Local Variables: ***
*** coq-load-path: (("../../../coq" "QCert")) ***
*** End: ***
*)
