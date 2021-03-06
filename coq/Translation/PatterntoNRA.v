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

Section PatterntoNRA.

  Require Import String.
  Require Import List.

  Require Import Utils BasicRuntime.
  Require Import NRARuntime.
  Require Import Pattern.
  
  Local Open Scope string_scope.
  Local Open Scope list_scope.

  Context {fruntime:foreign_runtime}.

  (* Output encoding *)

  Definition lift_failure d :=
    match d with
      | TerminalError => None
      | RecoverableError => Some (dcoll nil)
      | Success d' => Some (dcoll (d'::nil))
    end.

  (** Translation from CAMP to NRA *)

  Fixpoint alg_of_pat (p:pat) : alg :=
    match p with
      | pconst d' => pat_match (AConst d')
      | punop uop p₁ => AMap (AUnop uop AID) (alg_of_pat p₁)
      | pbinop bop p₁ p₂ =>
        AMap (ABinop bop (AUnop (ADot "a1") AID) (AUnop (ADot "a2") AID))
             (AProduct (AMap (AUnop (ARec "a1") AID) (alg_of_pat p₁))
                       (AMap (AUnop (ARec "a2") AID) (alg_of_pat p₂)))
      | pmap p₁ =>
        pat_match
          (AUnop AFlatten
                 (AMap
                    (alg_of_pat p₁)
                    (unnest_two
                       "a1"
                       "PDATA"
                       (AUnop AColl (pat_wrap_a1 (AUnop (ADot "PDATA") AID))))))
      | passert p₁ => AMap (AConst (drec nil)) (ASelect AID (alg_of_pat p₁))
      | porElse p₁ p₂ => ADefault (alg_of_pat p₁) (alg_of_pat p₂)
      | pit => pat_match pat_data
      | pletIt p₁ p₂ =>
        AUnop AFlatten
              (AMap (alg_of_pat p₂)
                    (unnest_two
                       "a1"
                       "PDATA"
                       (AUnop AColl
                              (pat_wrap_a1 (alg_of_pat p₁)))))
      | pgetconstant s => pat_match (AUnop (ADot s) pat_const_env)
      | penv => pat_match pat_bind
      | pletEnv p₁ p₂ =>
        AUnop AFlatten
              (AMap
                 (alg_of_pat p₂)
                 (unnest_two (* Needed because MergeConcat may fail so is a
                                collection which must be unnested *)
                    "PBIND1"
                    "PBIND"
                    (AMap (ABinop AConcat
                                  (AUnop (ARec "PDATA") (AUnop (ADot "PDATA") AID))
                                   (ABinop AConcat
                                           (AUnop (ARec "PCONST") (AUnop (ADot "PCONST") AID))
                                           (AUnop (ARec "PBIND1") (ABinop AMergeConcat
                                                                 (AUnop (ADot "PBIND") AID)
                                                                 (AUnop (ADot "PBIND1") AID)))))
                          (unnest_two
                             "a1"
                             "PBIND1"
                             (AUnop AColl
                                    (ABinop AConcat
                                            AID
                                            (AUnop (ARec "a1") (alg_of_pat p₁))))))))
      | pleft =>
        AApp (AEither (pat_match AID) (pat_fail)) pat_data
      | pright =>
        AApp (AEither (pat_fail) (pat_match AID)) pat_data
    end.

  (** top level version sets up the appropriate input 
      (with an empty context) 
  *)

  Definition alg_of_pat_top c p :=
    AUnop AFlatten
          (AMap (alg_of_pat p)
                (AUnop AColl
                       (pat_context (AConst (drec c)) (AConst (drec nil)) AID))).

  (** Auxiliary lemmas -- all used inside pmap proof *)

  Lemma rmap_lift (l:list data) :
    rmap (fun x : data => Some (drec (("PDATA", x) :: nil))) l =
    Some (map (fun x => (drec (("PDATA", x) :: nil))) l).
  Proof.
    induction l; simpl. reflexivity.
    rewrite IHl.
    reflexivity.
  Qed.

  Lemma rmap_lift2 c bind (l l':list data):
    (rmap
       (fun x : data =>
          match x with
            | drec r1 =>
              Some
                (drec
                   (rec_concat_sort
                      (("PBIND", drec bind)
                         :: ("PCONST", c)
                         :: ("a1", dcoll l') :: nil) r1))
            | _ => None
          end)
       (map (fun x : data => drec (("PDATA", x) :: nil)) l)) =
    Some (map (fun x :data => (drec
                   (rec_concat_sort
                      (("PBIND", drec bind)
                         :: ("PCONST", c)
                         :: ("a1", dcoll l') :: nil) (("PDATA", x) :: nil)))) l). 
  Proof.
    induction l; simpl.
    reflexivity.
    rewrite IHl.
    simpl.
    reflexivity.
  Qed.

  Lemma rmap_lift3 c bind (l l':list data):
    rmap
      (fun x : data =>
         match x with
           | drec r => Some (drec (rremove r "a1"))
           | _ => None
         end)
      (map
         (fun x : data =>
            drec
              (rec_concat_sort
                 (("PBIND", drec bind)
                    :: ("PCONST", c)
                    :: ("a1", dcoll l') :: nil)
                 (("PDATA", x) :: nil))) l ++ nil)
    =
    Some (map (fun x : data =>
                 drec
                   (rec_concat_sort
                      (("PBIND", drec bind) :: ("PCONST", c) :: nil)
                      (("PDATA", x) :: nil))) l ++ nil).
  Proof.
    induction l; simpl.
    reflexivity.
    simpl.
    rewrite IHl.
    simpl.
    reflexivity.
  Qed.

  Lemma rflatten_lift1 (l:option (list data)):
    (olift
       (fun d1 : data =>
          lift_oncoll (fun l0 : list data => lift dcoll (rflatten l0)) d1)
       (lift dcoll
             (lift (fun t' : list data => dcoll nil :: t') l))) =
     (olift
       (fun d1 : data =>
          lift_oncoll (fun l0 : list data => lift dcoll (rflatten l0)) d1)
       (lift dcoll l)).
  Proof.
    destruct l; try reflexivity.
    induction l; simpl; try reflexivity.
    simpl.
    unfold rflatten; simpl.
    assert (forall d, lift (fun t':list data => t') d = d).
    intros.
    destruct d; try reflexivity.
    rewrite H.
    reflexivity.
  Qed.

  (** Theorem 4.2: lemma of translation correctness for patterns *)

  Theorem pat_trans_correct {h:brand_relation_t} c p bind d:
    lift_failure (interp h c p bind d) = fun_of_alg h (alg_of_pat p) (pat_context_data (drec (rec_sort c)) (drec bind) d).
  Proof.
    revert d bind;
    pat_cases (induction p) Case; simpl; intros.
    - Case "pconst"%string.
      reflexivity.
    - Case "punop"%string.
      rewrite <- IHp; clear IHp; simpl.
      destruct (interp h c p bind d); try reflexivity.
      simpl; destruct (fun_of_unaryop h u res); reflexivity.
    - Case "pbinop"%string.
      rewrite <- IHp1; rewrite <- IHp2; clear IHp1 IHp2.
      destruct (interp h c p1 bind d); try reflexivity.
      destruct (interp h c p2 bind d); try reflexivity.
      simpl; destruct (fun_of_binop h b res res0); reflexivity.
    - Case "pmap"%string.
      destruct d; try reflexivity.
      unfold rmap_concat in *; simpl.
      unfold oomap_concat in *; simpl.
      rewrite rmap_lift; simpl.
      unfold omap_concat in *; simpl.
      rewrite rmap_lift2; simpl.
      rewrite rmap_lift3; simpl.
      induction l; simpl; try reflexivity.
      unfold pat_context_data in IHp.
      assert ((rec_concat_sort (("PBIND", drec bind) :: ("PCONST", (drec (rec_sort c))) :: nil)
                   (("PDATA", a) :: nil)) =
              ("PBIND", drec bind) :: ("PCONST", (drec (rec_sort c))) :: ("PDATA", a) :: nil).
      reflexivity.
      rewrite H; clear H.
      rewrite <- (IHp a bind).
      clear IHp.
      destruct (interp h c p bind a); try reflexivity; simpl.
      rewrite IHl; simpl.
      rewrite rflatten_lift1.
      reflexivity.
      revert IHl.
      destruct ((rmap (fun_of_alg h (alg_of_pat p))
              (map
                 (fun x : data =>
                  drec
                    (rec_concat_sort (("PBIND", drec bind) :: ("PCONST", (drec (rec_sort c))) :: nil)
                       (("PDATA", x) :: nil))) l ++ nil))).
      * simpl. intros.
        unfold rflatten in *.
        simpl.
        revert IHl.
        destruct ((oflat_map
              (fun x : data =>
               match x with
               | dcoll y => Some y
               | _ => None
               end) l0)); simpl; intros;
        revert IHl;
        destruct (gather_successes (map (interp h c p bind) l)); intros; simpl in *; try reflexivity; congruence.
      * simpl.
        destruct ((gather_successes (map (interp h c p bind) l))); simpl; intros.
        reflexivity.
        congruence.
        congruence.
    - Case "passert"%string.
      rewrite <- IHp; clear IHp; simpl.
      destruct (interp h c p bind d); try reflexivity.
      destruct res; try reflexivity; simpl.
      destruct b; reflexivity.
    - Case "porElse"%string.
      rewrite <- IHp1; clear IHp1; simpl.
      destruct (interp h c p1 bind d); simpl; auto.
    - Case "pit"%string.
      reflexivity.
    - Case "pletIt"%string.
      rewrite <- IHp1; clear IHp1; simpl.
      destruct (interp h c p1 bind d); try reflexivity.
      simpl.
      specialize (IHp2 res).
      unfold pat_context_data in IHp2.
      rewrite <- IHp2; clear IHp2.
      destruct (interp h c p2 bind res); reflexivity.      
    - Case "pgetconstant"%string.
      unfold edot.
      rewrite (assoc_lookupr_drec_sort (odt:=ODT_string)).
      simpl.
      destruct (assoc_lookupr string_eqdec c s);
        simpl; trivial.
    - Case "penv"%string.
      eauto. 
    - Case "pletEnv"%string.
      rewrite <- IHp1; clear IHp1; simpl.
      destruct (interp h c p1 bind d); try reflexivity.
      destruct res; try reflexivity.
      simpl.
      destruct (merge_bindings bind l); try reflexivity.
      specialize (IHp2 d l0).
      unfold pat_context_data in *.
      simpl.
      rewrite <- IHp2; clear IHp2; simpl.
      destruct (interp h c p2 l0 d); try reflexivity.
    - Case "pleft"%string.
      unfold lift_failure. destruct d; simpl; trivial.
    - Case "pright"%string.
      unfold lift_failure. destruct d; simpl; trivial.
  Qed.

  Lemma pat_trans_yields_coll {h:brand_relation_t} p d d0:
    fun_of_alg h (alg_of_pat p) d = Some d0 ->
    {x | d0 = dcoll x}.
  Proof.
    Ltac findcol := 
      repeat match goal with
        | [H:context [ olift _ ?x] |- _ ] => 
          (case_eq x;  [intros ?|idtac]; intros eq; rewrite eq in H;
           simpl in *; try discriminate)
        | [H:context [ olift2 _ ?x ?y] |- _ ] => 
          (case_eq x; 
           [intros ?|idtac]; intros eq; rewrite eq in H;
           simpl in *; try discriminate);
            (case_eq y; 
             [intros ?|idtac]; intros eq2; rewrite eq2 in H;
             simpl in *; try discriminate)
        | [H:lift_oncoll _ ?d = Some _ |- _] => 
          destruct d; simpl in *; try discriminate
        | [H:lift _ _ = Some _ |- _ ] =>
          apply some_lift in H; destruct H; try subst
        | [H:Some _ = Some _ |- _ ] => inversion H; clear H; try subst
      end; eauto.
    revert d d0; induction p; simpl; intros; try findcol.
    destruct (IHp1 _ _ eq). subst.
    destruct x; findcol.
    destruct d; try congruence.
    destruct (edot l "PDATA"); try congruence.
    findcol.
    destruct d1; try congruence;
    [ exists (d1::nil); congruence | exists (nil); congruence].
    destruct d1; try congruence;
    [ exists nil; congruence | exists (d1::nil); congruence].
  Qed.

  Lemma pat_trans_top_pat_context {h:brand_relation_t} c p d:
    Forall (fun x => data_normalized h (snd x)) c ->
    fun_of_alg h (alg_of_pat_top c p) d 
    = fun_of_alg h (alg_of_pat p) (pat_context_data (drec (rec_sort c)) (drec nil) d).
  Proof.
    simpl.
    unfold olift, pat_context_data; intros.
    rewrite map_normalize_normalized_eq; trivial.
    - case_eq (h ⊢ (alg_of_pat p) @ₐ (drec (("PBIND", drec nil) :: ("PCONST", (drec (rec_sort c))) :: ("PDATA", d) :: nil))); simpl; trivial.
    intros.
    unfold rflatten.
    simpl.
    apply pat_trans_yields_coll in H0.
    destruct H0; subst; simpl.
    rewrite app_nil_r. trivial.
  Qed.

  Lemma pat_trans_top_correct {h:brand_relation_t} c p d:
    Forall (fun x => data_normalized h (snd x)) c ->
    lift_failure (interp h c p nil d) = fun_of_alg h (alg_of_pat_top c p) d.
  Proof.
    intros.
    rewrite pat_trans_top_pat_context by trivial.
    apply pat_trans_correct.
  Qed.

  (* Wrapping the error on the NRA side might be a little nicer, notably for later
     top-level proofs *)

  Definition lift_pat_failure (d : option data) :=
    match d with
      | Some (dcoll nil) => RecoverableError
      | Some (dcoll (l::nil)) => Success l
      | _ => TerminalError
    end.

  Lemma pat_trans_correct_r {h:brand_relation_t} c p bind d:
      interp h c p bind d =
      lift_pat_failure (fun_of_alg h (alg_of_pat p) (pat_context_data (drec (rec_sort c)) (drec bind) d)).
  Proof.
    rewrite <- pat_trans_correct.
    destruct (interp h c p bind d); intros; simpl; reflexivity.
  Qed.

  Lemma pat_trans_top_correct_r {h:brand_relation_t} c p d:
    Forall (fun x => data_normalized h (snd x)) c ->
      interp h c p nil d =
      lift_pat_failure (fun_of_alg h (alg_of_pat_top c p) d).
  Proof.
    intros.
    rewrite <- pat_trans_top_correct by trivial.
    destruct (interp h c p nil d); intros; simpl; eauto.
  Qed.

Section size.
  Require Import PatternSize.
  Require Import RAlgSize.
  Require Import Omega.

  (** Proof showing linear size translation *)
  Lemma pat_trans_size p :
    alg_size (alg_of_pat p) <= 41 * pat_size p.
  Proof.
    induction p; simpl; omega.
  Qed.

End size.

End PatterntoNRA.

(* 
*** Local Variables: ***
*** coq-load-path: (("../../coq" "QCert")) ***
*** End: ***
*)
