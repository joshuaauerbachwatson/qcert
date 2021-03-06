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

Section DConstants.

  Require Import String.
  Require Import List.
  Require Import EquivDec.
  Require Import RList RAssoc.
  Require Import RData DData RRelation.

  Require Import RConstants.
  
  Local Open Scope string.

  Require Import ForeignData.

  Context {fdata:foreign_data}.

  (* Java equivalent: NnrcToNrcmr.localize_names *)
  Definition mkDistNames (names: list string) : list (string * dlocalization) :=
    map (fun x => (x, Vdistr)) names.

  Definition mkDistLocs {A} (cenv: list (string * A)) : list (string * dlocalization) :=
    mkDistNames (map fst cenv).

  Definition mkDistConstants
             (vars_loc: list (string * dlocalization)) (env: list (string*data))
    : option (list (string*ddata)) :=
    let one (x_loc: string * dlocalization) :=
        let (x, loc) := x_loc in
        match lookup equiv_dec env x with
        | Some d =>
          match loc with
          | Vlocal => Some (x, Dlocal d)
          | Vdistributed =>
            match d with
            | dcoll coll => Some (x, Ddistr coll)
            | _ => None
            end
          end
        | None => None
        end
    in
    rmap one vars_loc.

  Section World.
    (* Declares single *distributed* input collection containing world *)
    Definition mkDistWorld (world:list data) : list (string*ddata)
      := (WORLD, Ddistr world)::nil.

    (* Declares single *distributed* input collection containing world *)
    Definition mkDistLoc : list (string*dlocalization)
      := (WORLD, Vdistr)::nil.
  End World.

End DConstants.

(* 
*** Local Variables: ***
*** coq-load-path: (("../../../coq" "QCert")) ***
*** End: ***
*)
