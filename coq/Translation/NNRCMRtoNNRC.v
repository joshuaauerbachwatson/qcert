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

Require Import Arith.
Require Import ZArith.
Require Import String.
Require Import List.
Require Import EquivDec.

Require Import Utils BasicRuntime.
Require Import NNRCRuntime NNRCMRRuntime ForeignToReduceOps.

Local Open Scope list_scope.

(* Section NNRCMRtoNNRC. *)

(*   Context {fruntime:foreign_runtime}. *)
(*   Context {fredop:foreign_reduce_op}. *)
(*   Context {ftoredop:foreign_to_reduce_op}. *)

(*   Context (h:brand_relation_t). *)

(*   Definition map_to_nnrc (map:map_fun) (inputn:nrc) := *)
(*     match map with *)
(*     | MapDist (v, n) => *)
(*       NRCFor v inputn n *)
(*     | MapDistFlatten (v, n) => *)
(*       NRCUnop AFlatten (NRCFor v inputn n) *)
(*     | MapScalar (v, n) => *)
(*       NRCUnop AFlatten (NRCFor v (NRCUnop AColl inputn) n) *)
(*     end. *)

(*   Lemma rmap_function_with_no_free_vars_env v n l env : *)
(*     function_with_no_free_vars (v, n) -> *)
(*     rmap (fun d : data => nrc_eval h ((v, d) :: nil) n) l = *)
(*     rmap (fun d1 : data => nrc_eval h ((v, d1) :: env) n) l. *)
(*   Proof. *)
(*     intros. *)
(*     induction l; try reflexivity. *)
(*     simpl. *)
(*     unfold function_with_no_free_vars in *; simpl in *. *)
(*     rewrite <- (nrc_eval_single_context_var_cons h env n v a H). *)
(*     destruct (nrc_eval h ((v, a) :: nil) n). *)
(*     - rewrite IHl; reflexivity. *)
(*     - reflexivity. *)
(*   Qed. *)
  
(*   Lemma map_to_nnrc_correct env (map:map_fun) (input_d:ddata) (inputn:nrc) : *)
(*     map_well_formed map -> *)
(*     map_well_localized map input_d -> *)
(*     nrc_eval h env inputn = Some (unlocalize_data input_d) -> *)
(*     lift dcoll (mr_map_eval h map input_d) = nrc_eval h env (map_to_nnrc map inputn). *)
(*   Proof. *)
(*     intros. *)
(*     destruct map; destruct input_d; simpl in *; try contradiction. *)
(*     - destruct p; simpl. *)
(*       rewrite H1. *)
(*       f_equal. *)
(*       apply (rmap_function_with_no_free_vars_env _ _ _ _ H). *)
(*     - destruct p; simpl. *)
(*       rewrite H1; simpl. *)
(*       autorewrite with alg. *)
(*       f_equal; f_equal. *)
(*       apply (rmap_function_with_no_free_vars_env _ _ _ _ H). *)
(*     - destruct p; simpl. *)
(*       rewrite H1; simpl. *)
(*       rewrite (nrc_eval_single_context_var_cons h env n v d H). *)
(*       destruct (nrc_eval h ((v, d) :: env) n); simpl; try reflexivity. *)
(*       unfold rflatten; simpl. *)
(*       destruct d0; try reflexivity. *)
(*       rewrite app_nil_r. *)
(*       reflexivity. *)
(*   Qed. *)

(*   Definition foreign_of_reduce_op (op:reduce_op) := *)
(*     match op with *)
(*     | RedOpForeign fop => NRCConst dunit (* Need Louis or Avi's advice here *) *)
(*     end. *)
  
(*   Definition reduce_to_nnrc (red:reduce_fun) (inputn:nrc) : nrc := *)
(*     match red with *)
(*     | RedId => inputn *)
(*     | RedCollect (v, n) => NRCLet v inputn n *)
(*     | RedOp op => (foreign_of_reduce_op op) *)
(*     | RedSingleton => NRCConst dunit (* This will be a problem, again, ...*) *)
(*     end. *)
  
(*   Lemma reduce_to_nnrc_correct env (red:reduce_fun) (input_d:list data) (inputn:nrc) : *)
(*     reduce_well_formed red -> *)
(*     nrc_eval h env inputn = Some (dcoll input_d) -> *)
(*     lift unlocalize_data (mr_reduce_eval h red input_d) = nrc_eval h env (reduce_to_nnrc red inputn). *)
(*   Proof. *)
(*     intros. *)
(*     destruct red; simpl in *. *)
(*     (* RedId *) *)
(*     - auto. *)
(*     (* RedCollect *) *)
(*     - destruct p; simpl. *)
(*       rewrite H0; simpl. *)
(*       rewrite <- (nrc_eval_single_context_var_cons h env n v (dcoll input_d) H). *)
(*       destruct (nrc_eval h ((v, dcoll input_d) :: nil) n); reflexivity. *)
(*     (* RedOp *) *)
(*     - admit. *)
(*     (* RedSingleton *) *)
(*     - admit. *)
(*   Admitted. *)

(*   Definition map_reduce_to_nnrc (inputn:nrc) (map:map_fun) (reduce:reduce_fun) := *)
(*     reduce_to_nnrc reduce (map_to_nnrc map inputn). *)
  
(*   Definition nnrcmr_to_nnrc (mr:mr) : nrc := *)
(*     NRCLet (mr_output mr) *)
(*            (map_reduce_to_nnrc (NRCVar (mr_input mr)) (mr_map mr) (mr_reduce mr)) *)
(*            (NRCVar (mr_output mr)). *)

(* End NNRCMRtoNNRC. *)

Section NNRCMRtoNNRC.

  Context {fruntime:foreign_runtime}.
  Context {fredop:foreign_reduce_op}.
  Context {ftoredop:foreign_to_reduce_op}.

  Context (h:brand_relation_t).

  (* Generates the DNNRC code corresponding to "(fun x => e1) e2" that is:
       let x = e2 in e1
   *)
  Definition gen_apply_fun (f: var * nrc) (e2: nrc) : nrc :=
    let (x, e1) := f in
    NRCLet x e2
           e1.

  (* Generates the DNNRC code corresponding to "(fun (x1, ..., xn) => e) (e1, ..., en)" that is:
       let x1 = e1 in
       ...
       let xn = en in
       e
   *)
  Fixpoint gen_apply_fun_n (f: list var * nrc)  (eff: list (var * dlocalization)) : option nrc :=
    let (form, e) := f in
    lift (List.fold_right
            (fun t k =>
               let '(x, (y, loc)) := t in
               NRCLet x (NRCVar y)
                      k)
            e)
         (zip form eff).


  Definition nnrc_of_mr_map (input: var) (mr_map: map_fun) : nrc :=
    match mr_map with
    | MapDist (x, n) =>
      NRCFor x (NRCVar input) n
    | MapDistFlatten (x, n) =>
      let res_map :=
          NRCFor x (NRCVar input) n
      in
      NRCUnop AFlatten res_map
    | MapScalar (x, n) =>
      NRCFor x (NRCVar input) n
    end.

  Definition nnrc_of_mr (m:mr) : option nrc :=
    match (m.(mr_map), m.(mr_reduce)) with
    | (MapScalar (x, NRCUnop AColl n), RedSingleton) =>
      Some (gen_apply_fun (x, n) (NRCVar m.(mr_input)))
    | (_, RedSingleton) =>
      None
    | (map, RedId) =>
      Some (nnrc_of_mr_map (mr_input m) map)
    | (map, RedCollect red_fun) =>
      let map_expr := nnrc_of_mr_map (mr_input m) map in
      Some (gen_apply_fun red_fun map_expr)
    | (map, RedOp op) =>
      match op with
      | RedOpForeign frop =>
        let map_expr := nnrc_of_mr_map (mr_input m) map in
        lift (fun op => NRCUnop op map_expr) (foreign_to_reduce_op_to_unary_op op)
      end
    end.

  Fixpoint nnrc_of_mr_chain (outputs: list var) (l: list mr) (k: nrc) : option nrc :=
    match l with
    | nil => Some k
    | mr :: l =>
      match (nnrc_of_mr mr, nnrc_of_mr_chain (mr_output mr :: outputs) l k) with
      | (Some n, Some k) =>
        Some (NRCLet
                (mr_output mr)
                (if in_dec equiv_dec (mr_output mr) outputs then
                   NRCBinop AUnion (NRCVar (mr_output mr)) n
                 else n)
                k)
      | _ => None
      end
    end.

  Definition nnrc_of_nrcmr (l: nrcmr) : option nrc :=
    let (last_fun, last_args) :=  mr_last l in
    let k := gen_apply_fun_n last_fun last_args in
    olift (nnrc_of_mr_chain nil (mr_chain l)) k.

End NNRCMRtoNNRC.


(*
*** Local Variables: ***
*** coq-load-path: (("../../coq" "QCert")) ***
*** End: ***
*)
