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

(*******************************
 * Algebra contexts *
 *******************************)

Section RAlgContext.

  Require Import Equivalence.
  Require Import Morphisms.
  Require Import Setoid.
  Require Import EquivDec.
  Require Import Program.

  Require Import List Permutation.
  Require Import String.
  Require Import NPeano.
  Require Import Arith.
  Require Import Bool.

  Require Import Utils BasicRuntime.
  Require Import RAlg RAlgEq.
  Require Import RBindingsNat.

  Local Open Scope alg_scope.

  Context {fruntime:foreign_runtime}.

  Inductive alg_ctxt : Set :=
  | CHole : nat -> alg_ctxt
  | CPlug : alg -> alg_ctxt
  | CABinop : binOp -> alg_ctxt -> alg_ctxt -> alg_ctxt
  | CAUnop : unaryOp -> alg_ctxt -> alg_ctxt
  | CAMap : alg_ctxt -> alg_ctxt -> alg_ctxt
  | CAMapConcat : alg_ctxt -> alg_ctxt -> alg_ctxt
  | CAProduct : alg_ctxt -> alg_ctxt -> alg_ctxt
  | CASelect : alg_ctxt -> alg_ctxt -> alg_ctxt
  | CADefault : alg_ctxt -> alg_ctxt -> alg_ctxt
  | CAEither : alg_ctxt -> alg_ctxt -> alg_ctxt
  | CAEitherConcat : alg_ctxt -> alg_ctxt -> alg_ctxt
  | CAApp : alg_ctxt -> alg_ctxt -> alg_ctxt
  .

  Definition CAID : alg_ctxt
    := CPlug AID.

  Definition CAConst : data -> alg_ctxt
    := fun d => CPlug (AConst d).

  Fixpoint ac_holes (c:alg_ctxt) : list nat :=
    match c with
      | CHole x => x::nil
      | CPlug a => nil
      | CABinop b c1 c2 => ac_holes c1 ++ ac_holes c2
      | CAUnop u c' => ac_holes c'
      | CAMap c1 c2 => ac_holes c1 ++ ac_holes c2
      | CAMapConcat c1 c2 => ac_holes c1 ++ ac_holes c2
      | CAProduct c1 c2 => ac_holes c1 ++ ac_holes c2
      | CASelect c1 c2 => ac_holes c1 ++ ac_holes c2
      | CADefault c1 c2 => ac_holes c1 ++ ac_holes c2
      | CAEither c1 c2 => ac_holes c1 ++ ac_holes c2
      | CAEitherConcat c1 c2 => ac_holes c1 ++ ac_holes c2
      | CAApp c1 c2 => ac_holes c1 ++ ac_holes c2
    end.

  Fixpoint ac_simplify (c:alg_ctxt) : alg_ctxt :=
    match c with
      | CHole x => CHole x
      | CPlug a => CPlug a
      | CABinop b c1 c2 =>
        match ac_simplify c1, ac_simplify c2 with
          | (CPlug a1), (CPlug a2) => CPlug (ABinop b a1 a2)
          | c1', c2' => CABinop b c1' c2'
        end
      | CAUnop u c =>
        match ac_simplify c with
          | CPlug a => CPlug (AUnop u a)
          | c' => CAUnop u c'
        end
      | CAMap c1 c2 =>
        match ac_simplify c1, ac_simplify c2 with
          | (CPlug a1), (CPlug a2) => CPlug (AMap a1 a2)
          | c1', c2' => CAMap c1' c2'
        end
      | CAMapConcat c1 c2 =>
        match ac_simplify c1, ac_simplify c2 with
          | (CPlug a1), (CPlug a2) => CPlug (AMapConcat a1 a2)
          | c1', c2' => CAMapConcat c1' c2'
        end
      | CAProduct c1 c2 =>
        match ac_simplify c1, ac_simplify c2 with
          | (CPlug a1), (CPlug a2) => CPlug (AProduct a1 a2)
          | c1', c2' => CAProduct c1' c2'
        end
      | CASelect c1 c2 =>
        match ac_simplify c1, ac_simplify c2 with
          | (CPlug a1), (CPlug a2) => CPlug (ASelect a1 a2)
          | c1', c2' => CASelect c1' c2'
        end
      | CADefault c1 c2 =>
        match ac_simplify c1, ac_simplify c2 with
          | (CPlug a1), (CPlug a2) => CPlug (ADefault a1 a2)
          | c1', c2' => CADefault c1' c2'
        end
      | CAEither c1 c2 =>
        match ac_simplify c1, ac_simplify c2 with
          | (CPlug a1), (CPlug a2) => CPlug (AEither a1 a2)
          | c1', c2' => CAEither c1' c2'
        end
      | CAEitherConcat c1 c2 =>
        match ac_simplify c1, ac_simplify c2 with
          | (CPlug a1), (CPlug a2) => CPlug (AEitherConcat a1 a2)
          | c1', c2' => CAEitherConcat c1' c2'
        end
      | CAApp c1 c2 =>
        match ac_simplify c1, ac_simplify c2 with
          | (CPlug a1), (CPlug a2) => CPlug (AApp a1 a2)
          | c1', c2' => CAApp c1' c2'
        end
    end.

  Lemma ac_simplify_holes_preserved c :
    ac_holes (ac_simplify c) = ac_holes c.
  Proof.
    induction c; simpl; trivial;
    try solve [destruct (ac_simplify c1); destruct (ac_simplify c2);
      unfold ac_holes in *; fold ac_holes in *;
      repeat rewrite <- IHc1; repeat rewrite <- IHc2; simpl; trivial].
    try solve [destruct (ac_simplify c);
      unfold ac_holes in *; fold ac_holes in *;
      repeat rewrite <- IHc; simpl; trivial].
  Qed.

  Definition ac_alg_of_ctxt c
    := match (ac_simplify c) with
         | CPlug a => Some a
         | _ => None
       end.

  Lemma ac_simplify_nholes c :
    ac_holes c = nil -> {a | ac_simplify c = CPlug a}.
  Proof.
    induction c; simpl; [discriminate | eauto 2 | ..];
    try solve [intros s0; apply app_eq_nil in s0;
      destruct s0 as [s10 s20];
      destruct (IHc1 s10) as [a1 e1];
        destruct (IHc2 s20) as [a2 e2];
        rewrite e1, e2; eauto 2].
    (* unary operator case *)
    intros s0; destruct (IHc s0) as [a e];
    rewrite e; eauto 2.
  Defined.

  Lemma ac_alg_of_ctxt_nholes c :
    ac_holes c = nil -> {a | ac_alg_of_ctxt c = Some a}.
  Proof.
    intros ac0.
    destruct (ac_simplify_nholes _ ac0).
    unfold ac_alg_of_ctxt.
    rewrite e.
    eauto.
  Qed.

  Lemma ac_simplify_idempotent c :
    ac_simplify (ac_simplify c) = ac_simplify c.
    (* ** TODO: This proof is correct, but takes a loooong time. ***
  Proof.
    induction c; simpl; trivial;
    try solve [destruct (ac_simplify c); simpl in *; trivial;
               match_destr; try congruence
              | destruct (ac_simplify c1); simpl;
                 try rewrite IHc2; trivial;
                 destruct (ac_simplify c2); simpl in *; trivial;
                 match_destr; try congruence].
  Qed.
*)
  Admitted. (* proof takes annoyingly long to compute (but is there) *)

  Fixpoint ac_subst (c:alg_ctxt) (x:nat) (p:alg) : alg_ctxt :=
    match c with
      | CHole x'
        => if x == x' then CPlug p else CHole x'
      | CPlug a
        => CPlug a
      | CABinop b c1 c2
        => CABinop b (ac_subst c1 x p) (ac_subst c2 x p)
      | CAUnop u c
        => CAUnop u (ac_subst c x p)
      | CAMap c1 c2
        => CAMap (ac_subst c1 x p) (ac_subst c2 x p)
      | CAMapConcat c1 c2
        => CAMapConcat (ac_subst c1 x p) (ac_subst c2 x p)
      | CAProduct c1 c2
        => CAProduct (ac_subst c1 x p) (ac_subst c2 x p)
      | CASelect c1 c2
        => CASelect (ac_subst c1 x p) (ac_subst c2 x p)
      | CADefault c1 c2
        => CADefault (ac_subst c1 x p) (ac_subst c2 x p)
      | CAEither c1 c2
        => CAEither (ac_subst c1 x p) (ac_subst c2 x p)
      | CAEitherConcat c1 c2
        => CAEitherConcat (ac_subst c1 x p) (ac_subst c2 x p)
      | CAApp c1 c2
        => CAApp (ac_subst c1 x p) (ac_subst c2 x p)
    end.

  Definition ac_substp (c:alg_ctxt) xp
    := let '(x, p) := xp in ac_subst c x p.
    
  Definition ac_substs c ps :=
    fold_left ac_substp ps c.

    Lemma ac_substs_app c ps1 ps2 :
     ac_substs c (ps1 ++ ps2) =
     ac_substs (ac_substs c ps1) ps2.
   Proof.
     unfold ac_substs.
     apply fold_left_app.
   Qed.
   
  Lemma ac_subst_holes_nin  c x p :
    ~ In x (ac_holes c) -> ac_subst c x p = c.
  Proof.
    induction c; simpl; intros; 
    [match_destr; intuition | trivial | .. ];
    repeat rewrite in_app_iff in *;
    f_equal; auto.
  Qed.
  
  Lemma ac_subst_holes_remove c x p :
    ac_holes (ac_subst c x p) = (remove_all x (ac_holes c)).
  Proof.
    induction c; simpl; intros;
    trivial; try solve[ rewrite remove_all_app; congruence].
    (* CHole *)
    match_destr; match_destr; simpl; try rewrite app_nil_r; congruence.
  Qed.

  Lemma ac_substp_holes_remove c xp :
      ac_holes (ac_substp c xp) = remove_all (fst xp) (ac_holes c).
  Proof.
    destruct xp; simpl.
    apply ac_subst_holes_remove.
  Qed.

  Lemma ac_substs_holes_remove c ps :
    ac_holes (ac_substs c ps) =
    fold_left (fun h xy => remove_all (fst xy) h) ps (ac_holes c).
  Proof.
    revert c.
    unfold ac_substs.
    induction ps; simpl; trivial; intros.
    rewrite IHps, ac_substp_holes_remove.
    trivial.
  Qed.

  Lemma ac_substs_Plug a ps :
    ac_substs (CPlug a) ps = CPlug a.
  Proof.
    induction ps; simpl; trivial; intros.
    destruct a0; simpl; auto.
  Qed.
  
  Lemma ac_substs_Binop b c1 c2 ps :
    ac_substs (CABinop b c1 c2) ps = CABinop b (ac_substs c1 ps) (ac_substs c2 ps).
  Proof.
    revert c1 c2.
    induction ps; simpl; trivial; intros.
    destruct a; simpl; auto.
  Qed.

  Lemma ac_substs_Unop u c ps :
      ac_substs (CAUnop u c) ps = CAUnop u (ac_substs c ps).
  Proof.
    revert c.
    induction ps; simpl; trivial; intros.
    destruct a; simpl; auto.
  Qed.

  Lemma ac_substs_Map c1 c2 ps :
    ac_substs ( CAMap c1 c2) ps =
    CAMap (ac_substs c1 ps) (ac_substs c2 ps).
  Proof.
    revert c1 c2.
    induction ps; simpl; trivial; intros.
    destruct a; simpl; auto.
  Qed.

  Lemma ac_substs_MapConcat c1 c2 ps :
    ac_substs ( CAMapConcat c1 c2) ps =
    CAMapConcat (ac_substs c1 ps) (ac_substs c2 ps).
  Proof.
    revert c1 c2.
    induction ps; simpl; trivial; intros.
    destruct a; simpl; auto.
  Qed.
  
  Lemma ac_substs_Product c1 c2 ps :
    ac_substs ( CAProduct c1 c2) ps =
    CAProduct (ac_substs c1 ps) (ac_substs c2 ps).
  Proof.
    revert c1 c2.
    induction ps; simpl; trivial; intros.
    destruct a; simpl; auto.
  Qed.
  
  Lemma ac_substs_Select c1 c2 ps :
    ac_substs ( CASelect c1 c2) ps =
    CASelect (ac_substs c1 ps) (ac_substs c2 ps).
  Proof.
    revert c1 c2.
    induction ps; simpl; trivial; intros.
    destruct a; simpl; auto.
  Qed.
  
  Lemma ac_substs_Default c1 c2 ps :
    ac_substs ( CADefault c1 c2) ps =
    CADefault (ac_substs c1 ps) (ac_substs c2 ps).
  Proof.
    revert c1 c2.
    induction ps; simpl; trivial; intros.
    destruct a; simpl; auto.
  Qed.
  
  Lemma ac_substs_Either c1 c2 ps :
    ac_substs ( CAEither c1 c2) ps =
    CAEither (ac_substs c1 ps) (ac_substs c2 ps).
  Proof.
    revert c1 c2.
    induction ps; simpl; trivial; intros.
    destruct a; simpl; auto.
  Qed.
  
  Lemma ac_substs_EitherConcat c1 c2 ps :
    ac_substs ( CAEitherConcat c1 c2) ps =
    CAEitherConcat (ac_substs c1 ps) (ac_substs c2 ps).
  Proof.
    revert c1 c2.
    induction ps; simpl; trivial; intros.
    destruct a; simpl; auto.
  Qed.
  
  Lemma ac_substs_App c1 c2 ps :
    ac_substs ( CAApp c1 c2) ps =
    CAApp (ac_substs c1 ps) (ac_substs c2 ps).
  Proof.
    revert c1 c2.
    induction ps; simpl; trivial; intros.
    destruct a; simpl; auto.
  Qed.

  Hint Rewrite
       ac_substs_Plug
       ac_substs_Binop
       ac_substs_Unop
       ac_substs_Map
       ac_substs_MapConcat
       ac_substs_Product
       ac_substs_Select
       ac_substs_Default
       ac_substs_Either
       ac_substs_EitherConcat
       ac_substs_App : ac_substs.
  
  Lemma ac_simplify_holes_binop b c1 c2:
    ac_holes (CABinop b c1 c2) <> nil ->
    ac_simplify (CABinop b c1 c2) = CABinop b (ac_simplify c1) (ac_simplify c2).
  Proof.
    intros.
    simpl in H.
    generalize (ac_simplify_holes_preserved c1); intros pres1;
      generalize (ac_simplify_holes_preserved c2); intros pres2;
      simpl; intros.
    do 2 match_destr.
    simpl in *; rewrite <- pres1, <- pres2 in H.
    simpl in H; intuition.
  Qed.

  Lemma ac_simplify_holes_unop u c:
    ac_holes (CAUnop u c ) <> nil ->
    ac_simplify (CAUnop u c) = CAUnop u (ac_simplify c).
  Proof.
    intros.
    simpl in H.
    generalize (ac_simplify_holes_preserved c); intros pres1;
      simpl; intros.
    match_destr.
    simpl in *; rewrite <- pres1 in H.
    simpl in H; intuition.
  Qed.

  Lemma ac_simplify_holes_map c1 c2:
    ac_holes (CAMap c1 c2) <> nil ->
    ac_simplify (CAMap c1 c2) = CAMap (ac_simplify c1) (ac_simplify c2).
  Proof.
    intros.
    simpl in H.
    generalize (ac_simplify_holes_preserved c1); intros pres1;
      generalize (ac_simplify_holes_preserved c2); intros pres2;
      simpl; intros.
    do 2 match_destr.
    simpl in *; rewrite <- pres1, <- pres2 in H.
    simpl in H; intuition.
  Qed.

    Lemma ac_simplify_holes_mapconcat c1 c2:
    ac_holes (CAMapConcat c1 c2) <> nil ->
    ac_simplify (CAMapConcat c1 c2) = CAMapConcat (ac_simplify c1) (ac_simplify c2).
  Proof.
    intros.
    simpl in H.
    generalize (ac_simplify_holes_preserved c1); intros pres1;
      generalize (ac_simplify_holes_preserved c2); intros pres2;
      simpl; intros.
    do 2 match_destr.
    simpl in *; rewrite <- pres1, <- pres2 in H.
    simpl in H; intuition.
  Qed.

    Lemma ac_simplify_holes_product c1 c2:
    ac_holes (CAProduct c1 c2) <> nil ->
    ac_simplify (CAProduct c1 c2) = CAProduct (ac_simplify c1) (ac_simplify c2).
  Proof.
    intros.
    simpl in H.
    generalize (ac_simplify_holes_preserved c1); intros pres1;
      generalize (ac_simplify_holes_preserved c2); intros pres2;
      simpl; intros.
    do 2 match_destr.
    simpl in *; rewrite <- pres1, <- pres2 in H.
    simpl in H; intuition.
  Qed.

    Lemma ac_simplify_holes_select c1 c2:
    ac_holes (CASelect c1 c2) <> nil ->
    ac_simplify (CASelect c1 c2) = CASelect (ac_simplify c1) (ac_simplify c2).
  Proof.
    intros.
    simpl in H.
    generalize (ac_simplify_holes_preserved c1); intros pres1;
      generalize (ac_simplify_holes_preserved c2); intros pres2;
      simpl; intros.
    do 2 match_destr.
    simpl in *; rewrite <- pres1, <- pres2 in H.
    simpl in H; intuition.
  Qed.

    Lemma ac_simplify_holes_default c1 c2:
    ac_holes (CADefault c1 c2) <> nil ->
    ac_simplify (CADefault c1 c2) = CADefault (ac_simplify c1) (ac_simplify c2).
  Proof.
    intros.
    simpl in H.
    generalize (ac_simplify_holes_preserved c1); intros pres1;
      generalize (ac_simplify_holes_preserved c2); intros pres2;
      simpl; intros.
    do 2 match_destr.
    simpl in *; rewrite <- pres1, <- pres2 in H.
    simpl in H; intuition.
  Qed.

    Lemma ac_simplify_holes_either c1 c2:
    ac_holes (CAEither c1 c2) <> nil ->
    ac_simplify (CAEither c1 c2) = CAEither (ac_simplify c1) (ac_simplify c2).
  Proof.
    intros.
    simpl in H.
    generalize (ac_simplify_holes_preserved c1); intros pres1;
      generalize (ac_simplify_holes_preserved c2); intros pres2;
      simpl; intros.
    do 2 match_destr.
    simpl in *; rewrite <- pres1, <- pres2 in H.
    simpl in H; intuition.
  Qed.

    Lemma ac_simplify_holes_eitherconcat c1 c2:
    ac_holes (CAEitherConcat c1 c2) <> nil ->
    ac_simplify (CAEitherConcat c1 c2) = CAEitherConcat (ac_simplify c1) (ac_simplify c2).
  Proof.
    intros.
    simpl in H.
    generalize (ac_simplify_holes_preserved c1); intros pres1;
      generalize (ac_simplify_holes_preserved c2); intros pres2;
      simpl; intros.
    do 2 match_destr.
    simpl in *; rewrite <- pres1, <- pres2 in H.
    simpl in H; intuition.
  Qed.

    Lemma ac_simplify_holes_app c1 c2:
    ac_holes (CAApp c1 c2) <> nil ->
    ac_simplify (CAApp c1 c2) = CAApp (ac_simplify c1) (ac_simplify c2).
  Proof.
    intros.
    simpl in H.
    generalize (ac_simplify_holes_preserved c1); intros pres1;
      generalize (ac_simplify_holes_preserved c2); intros pres2;
      simpl; intros.
    do 2 match_destr.
    simpl in *; rewrite <- pres1, <- pres2 in H.
    simpl in H; intuition.
  Qed.

   Lemma ac_subst_nholes c x p :
     (ac_holes c) = nil -> ac_subst c x p = c.
   Proof.
     intros. apply ac_subst_holes_nin. rewrite H; simpl.
     intuition.
   Qed.

   Lemma ac_subst_simplify_nholes c x p :
     (ac_holes c) = nil ->
     ac_subst (ac_simplify c) x p = ac_simplify c.
   Proof.
     intros.
     rewrite (ac_subst_nholes (ac_simplify c)); trivial.
     rewrite ac_simplify_holes_preserved; trivial.
   Qed.

  Lemma ac_simplify_subst_simplify1 c x p :
    ac_simplify (ac_subst (ac_simplify c) x p) =
    ac_simplify (ac_subst c x p).
  Proof.
    Ltac destr_solv IHc1 IHc2 const lemma :=
      destruct (is_nil_dec (ac_holes const)) as [h|h];
      [(rewrite (ac_subst_nholes _ _ _ h);
        rewrite (ac_subst_simplify_nholes _ _ _ h);
        rewrite ac_simplify_idempotent;
        trivial)
      | (rewrite lemma; [| eauto];
        simpl;
        rewrite IHc1, IHc2; trivial)].

    induction c.
    - simpl; match_destr.
    - simpl; trivial.
    - destr_solv IHc1 IHc2 (CABinop b c1 c2) ac_simplify_holes_binop.
    -  destruct (is_nil_dec (ac_holes (CAUnop u c))) as [h|h].
      + rewrite (ac_subst_nholes _ _ _ h).
        rewrite (ac_subst_simplify_nholes _ _ _ h).
        rewrite ac_simplify_idempotent.
        trivial.
      + rewrite ac_simplify_holes_unop; [| eauto].
        simpl.
        rewrite IHc.
        trivial.
    - destr_solv IHc1 IHc2 (CAMap c1 c2) ac_simplify_holes_map.
    - destr_solv IHc1 IHc2 (CAMapConcat c1 c2) ac_simplify_holes_mapconcat.
    - destr_solv IHc1 IHc2 (CAProduct c1 c2) ac_simplify_holes_product.
    - destr_solv IHc1 IHc2 (CASelect c1 c2) ac_simplify_holes_select.
    - destr_solv IHc1 IHc2 (CADefault c1 c2) ac_simplify_holes_default.
    - destr_solv IHc1 IHc2 (CAEither c1 c2) ac_simplify_holes_either.
    - destr_solv IHc1 IHc2 (CAEitherConcat c1 c2) ac_simplify_holes_eitherconcat.
    - destr_solv IHc1 IHc2 (CAApp c1 c2) ac_simplify_holes_app.
  Qed.

  Lemma ac_simplify_substs_simplify1 c ps :
    ac_simplify (ac_substs (ac_simplify c) ps) =
    ac_simplify (ac_substs c ps).
  Proof.
    revert c.
    induction ps; simpl.
    - apply ac_simplify_idempotent.
    - destruct a. simpl; intros.
      rewrite <- IHps.
      rewrite ac_simplify_subst_simplify1.
      rewrite IHps; trivial.
  Qed.

  Section equivs.
    Context (base_equiv:alg->alg->Prop).
    
   Definition alg_ctxt_equiv (c1 c2 : alg_ctxt)
     := forall (ps:list (nat * alg)),
          match ac_simplify (ac_substs c1 ps),
                ac_simplify (ac_substs c2 ps)
          with
            | CPlug a1, CPlug a2 => base_equiv a1 a2
            | _, _ => True
          end.

   Definition alg_ctxt_equiv_strict (c1 c2 : alg_ctxt)
     := forall (ps:list (nat * alg)),
          is_list_sorted lt_dec (domain ps) = true ->
          equivlist (domain ps) (ac_holes c1 ++ ac_holes c2) ->
          match ac_simplify (ac_substs c1 ps),
                ac_simplify (ac_substs c2 ps)
          with
            | CPlug a1, CPlug a2 => base_equiv a1 a2
            | _, _ => True
          end.

   Global Instance ac_simplify_proper :
     Proper (alg_ctxt_equiv ==> alg_ctxt_equiv) ac_simplify.
  Proof.
    unfold Proper, respectful.
    unfold alg_ctxt_equiv.
    intros.
    repeat rewrite ac_simplify_substs_simplify1.
    specialize (H ps).
    match_destr; match_destr.
  Qed.
  
  Lemma ac_simplify_proper_inv x y:
    alg_ctxt_equiv (ac_simplify x) (ac_simplify y) -> alg_ctxt_equiv x y.
 Proof.
    unfold Proper, respectful.
    unfold alg_ctxt_equiv.
    intros.
    specialize (H ps).
    repeat rewrite ac_simplify_substs_simplify1 in H.
    match_destr; match_destr.
 Qed.

 Instance ac_subst_proper_part1 :
   Proper (alg_ctxt_equiv ==> eq ==> eq ==> alg_ctxt_equiv) ac_subst.
  Proof.
    unfold Proper, respectful, alg_ctxt_equiv.
    intros. subst.
    specialize (H ((y0,y1)::ps)).
    simpl in H.
    match_destr; match_destr.
  Qed.

  Global Instance ac_substs_proper_part1: Proper (alg_ctxt_equiv ==> eq ==> alg_ctxt_equiv) ac_substs.
  Proof.
    unfold Proper, respectful, alg_ctxt_equiv.
    intros. subst.
    repeat rewrite <- ac_substs_app.
    apply H.
  Qed.

  Definition alg_ctxt_equiv_strict1 (c1 c2 : alg_ctxt)
     := forall (ps:list (nat * alg)),
          NoDup (domain ps) ->
          equivlist (domain ps) (ac_holes c1 ++ ac_holes c2) ->
          match ac_simplify (ac_substs c1 ps),
                ac_simplify (ac_substs c2 ps)
          with
            | CPlug a1, CPlug a2 => base_equiv a1 a2
            | _, _ => True
          end.

   Lemma ac_subst_swap_neq c x1 x2 y1 y2 :
     x1 <> x2 ->
   ac_subst (ac_subst c x1 y1) x2 y2 =
   ac_subst (ac_subst c x2 y2) x1 y1.
   Proof.
     induction c; simpl;
     [ repeat (match_destr; simpl; try congruence) | trivial | .. ];
     intuition; congruence.
   Qed.
   
   Lemma ac_subst_swap_eq c x1 y1 y2 :
     ac_subst (ac_subst c x1 y1) x1 y2 =
     ac_subst c x1 y1.
   Proof.
      induction c; simpl;
      [ repeat (match_destr; simpl; try congruence) | trivial | .. ];
      intuition; congruence.
   Qed. 
           
   Lemma ac_substs_subst_swap_simpl x c y ps :
     ~ In x (domain ps) ->
      ac_substs (ac_subst c x y) ps
      =
      (ac_subst (ac_substs c ps) x y).
   Proof.
     revert c.
     induction ps; simpl; trivial; intros.
     rewrite <- IHps; trivial.
     + unfold ac_substp. destruct a.
       rewrite ac_subst_swap_neq; trivial.
       intuition.
     + intuition.
   Qed.
   
   Lemma ac_substs_perm c ps1 ps2 :
     NoDup (domain ps1) ->
     Permutation ps1 ps2 ->
     (ac_substs c ps1)  =
     (ac_substs c ps2).
   Proof.
     intros nd perm.
     revert c. revert ps1 ps2 perm nd.
     apply (Permutation_ind_bis
              (fun ps1 ps2 =>
                 NoDup (domain ps1) ->
                 forall c : alg_ctxt,
                   ac_substs c ps1 =
                   ac_substs c ps2 )); intros; simpl.
     - trivial.
     - inversion H1; subst. rewrite H0; trivial.
     - inversion H1; subst.
       inversion H5; subst.
       rewrite H0; trivial. destruct x; destruct y; simpl.
       rewrite ac_subst_swap_neq; trivial.
       simpl in *.
       intuition.
     - rewrite H0, H2; trivial.
       rewrite <- H. trivial.
   Qed. 
       
   (* They don't need to be sorted, as long as there are no duplicates *)
   Lemma alg_ctxt_equiv_strict_equiv1 (c1 c2 : alg_ctxt) :
     alg_ctxt_equiv_strict1 c1 c2 <-> alg_ctxt_equiv_strict c1 c2.
   Proof.
     unfold alg_ctxt_equiv_strict, alg_ctxt_equiv_strict1.
     split; intros.
     - apply H; trivial.
       apply is_list_sorted_NoDup in H0; trivial.
       apply Nat.lt_strorder.
     - specialize (H (rec_sort ps)).
       cut_to H.
       + Hint Resolve rec_sort_perm.
         rewrite ac_substs_perm with (c:=c1) (ps2:=(rec_sort ps)); auto.
         rewrite ac_substs_perm with (c:=c2) (ps2:=(rec_sort ps)); auto.
       + apply (@rec_sort_pf nat ODT_nat).
       + rewrite drec_sort_equiv_domain. trivial.
   Qed.

   (* we don't really need to worry about duplicates either *)
   Definition alg_ctxt_equiv_strict2 (c1 c2 : alg_ctxt)
     := forall (ps:list (nat * alg)),
          equivlist (domain ps) (ac_holes c1 ++ ac_holes c2) ->
          match ac_simplify (ac_substs c1 ps),
                ac_simplify (ac_substs c2 ps)
          with
            | CPlug a1, CPlug a2 => base_equiv a1 a2
            | _, _ => True
          end.

   Lemma ac_substs_in_nholes c x ps :
         In x (domain ps) ->
      ~ In x (ac_holes (ac_substs c ps)).
   Proof.
     rewrite ac_substs_holes_remove.
     intros.
     intros inn.
     apply (fold_left_remove_all_nil_in_not_inv inn); trivial.
   Qed. 
    
   Lemma substs_bdistinct_domain_rev c ps :
    (ac_substs c (bdistinct_domain (rev ps)))
    = 
    (ac_substs c ps).
  Proof.
    revert c.
    induction ps using rev_ind; simpl; trivial.
    rewrite rev_app_distr.
    simpl; intros.
    rewrite ac_substs_app.
    simpl.
    match_case; simpl; intros.
    - rewrite IHps.
      rewrite existsb_exists in H.
      destruct H as [? [? eqq]].
      unfold equiv_decb in eqq.
      match_destr_in eqq.
      destruct x; destruct x0; red in e; simpl in *.
      subst.
      apply in_dom in H.
      generalize (equivlist_in (bdistinct_domain_domain_equiv (rev ps)) _ H); intros eqq1.
      rewrite domain_rev in eqq1.
      generalize (Permutation_in _ (symmetry (Permutation_rev (domain ps))) eqq1); intros eqq2.
      rewrite ac_subst_holes_nin; trivial.
      apply ac_substs_in_nholes.
      trivial.
    - rewrite IHps.
      rewrite existsb_not_forallb, negb_false_iff, forallb_forall in H.
      destruct x; simpl.
      rewrite ac_substs_subst_swap_simpl; trivial.
      intros inn.
      apply bdistinct_rev_domain_equivlist in inn.
      apply in_domain_in in inn.
      destruct inn.
      specialize (H _ H0).
      unfold equiv_decb in *. match_destr_in H.
      simpl in *. intuition.
  Qed.
  
   Lemma alg_ctxt_equiv_strict1_equiv2 (c1 c2 : alg_ctxt) :
     alg_ctxt_equiv_strict2 c1 c2 <-> alg_ctxt_equiv_strict1 c1 c2.
   Proof.
     unfold alg_ctxt_equiv_strict1, alg_ctxt_equiv_strict2.
     split; intros H.
     - intros. apply H; trivial.
     - intros.
       specialize (H (bdistinct_domain (rev ps))).
       cut_to H.
       + repeat  rewrite substs_bdistinct_domain_rev in H.
          trivial.
       + apply bdistinct_domain_NoDup.
       + rewrite bdistinct_domain_domain_equiv.
         rewrite <- Permutation_rev.
         trivial.
   Qed.

   (* we don't really need to worry about having extra stuff either *)
   Definition alg_ctxt_equiv_strict3 (c1 c2 : alg_ctxt)
     := forall (ps:list (nat * alg)),
          incl (ac_holes c1 ++ ac_holes c2) (domain ps)  ->
          match ac_simplify (ac_substs c1 ps),
                ac_simplify (ac_substs c2 ps)
          with
            | CPlug a1, CPlug a2 => base_equiv a1 a2
            | _, _ => True
          end.
   
   Lemma cut_down_to_substs c ps cut :
     incl (ac_holes c) cut ->
     (ac_substs c ps) = (ac_substs c (cut_down_to ps cut)).
   Proof.
     revert c.
     induction ps; simpl; trivial; intros.
     match_case.
     - simpl; intros. apply IHps; simpl.
       rewrite ac_substp_holes_remove; simpl.
       rewrite remove_all_filter.
       red; intros ? inn.
       apply filter_In in inn. destruct inn as [inn1 ?].
       apply (H _ inn1).
     - destruct a. intros; simpl; rewrite ac_subst_holes_nin; eauto.
       rewrite existsb_not_forallb, negb_false_iff, forallb_forall in H0.
       intros inn; specialize (H _ inn).
       specialize (H0 _ H).
       unfold equiv_decb in *; match_destr_in H0.
       simpl in *.
       congruence.
   Qed.
         
   Lemma alg_ctxt_equiv_strict2_equiv3 (c1 c2 : alg_ctxt) :
     alg_ctxt_equiv_strict3 c1 c2 <-> alg_ctxt_equiv_strict2 c1 c2.
   Proof.
     unfold alg_ctxt_equiv_strict2, alg_ctxt_equiv_strict3.
     split; intros H.
     - intros. apply H; trivial. unfold equivlist, incl in *.
       intros; apply H0; trivial.
     - intros. specialize (H
                             (cut_down_to ps
                                          (ac_holes c1 ++ ac_holes c2))).
       cut_to H.
       + rewrite <- (cut_down_to_substs c1 ps (ac_holes c1 ++ ac_holes c2)) in H.
          rewrite <- (cut_down_to_substs c2 ps (ac_holes c1 ++ ac_holes c2)) in H.
         * trivial.
         * red; intros; rewrite in_app_iff; eauto.
         * red; intros; rewrite in_app_iff; eauto.
       + apply equivlist_incls; split.
         * apply cut_down_to_incl_to.
         * apply incl_domain_cut_down_incl; trivial.
   Qed.

   Lemma alg_ctxt_equiv_strict3_equiv (c1 c2 : alg_ctxt) :
     alg_ctxt_equiv c1 c2 <-> alg_ctxt_equiv_strict3 c1 c2.
   Proof.
     unfold alg_ctxt_equiv_strict3, alg_ctxt_equiv.
     intros.
      split; intros H.
     - intros. apply H; trivial.
     - intros ps.
       destruct (incl_dec (ac_holes c1 ++ ac_holes c2) (domain ps)).
       + apply (H ps); trivial.
       + apply nincl_exists in n. destruct n as [x [inx ninx]].
         rewrite in_app_iff in inx. destruct inx.
         * generalize (ac_substs_holes_remove c1 ps).
           rewrite <- ac_simplify_holes_preserved.
           match_destr; simpl; intros eqq.
           generalize (fold_left_remove_all_nil_in H0 ninx); intros inn.
           rewrite <- eqq in inn.
           inversion inn.
         * generalize (ac_substs_holes_remove c2 ps).
           rewrite <- ac_simplify_holes_preserved.
           match_destr; match_destr; simpl; intros eqq.
           generalize (fold_left_remove_all_nil_in H0 ninx); intros inn.
            rewrite <- eqq in inn.
           inversion inn.
   Qed.

   Theorem alg_ctxt_equiv_strict_equiv (c1 c2 : alg_ctxt) :
     alg_ctxt_equiv c1 c2 <-> alg_ctxt_equiv_strict c1 c2.
   Proof.
     rewrite alg_ctxt_equiv_strict3_equiv,
     alg_ctxt_equiv_strict2_equiv3,
     alg_ctxt_equiv_strict1_equiv2,
     alg_ctxt_equiv_strict_equiv1.
     reflexivity.
   Qed.

   Lemma ac_holes_saturated_subst {B} f c ps :
      incl (ac_holes c) (domain ps) ->
      ac_holes
        (ac_substs c
                   (map (fun xy : nat * B => (fst xy, (f (snd xy)))) ps)) = nil.
  Proof.
    intros.
    rewrite ac_substs_holes_remove, fold_left_map.
    simpl.
    replace (fold_left
     (fun (a : list nat) (b : nat * B) => remove_all (fst b) a)
     ps (ac_holes c) ) with
    ( fold_left
     (fun (a : list nat) (b : nat) =>  filter (nequiv_decb b) a)
     (map fst ps) (ac_holes c)).
    - case_eq (fold_left (fun (a : list nat) (b : nat) =>
                            filter (nequiv_decb b) a)
                         (map fst ps) (ac_holes c)); trivial.
      intros.
      assert (inn:In n (n::l)) by (simpl; intuition).
      rewrite <- H0 in inn.
      apply fold_left_remove_all_In in inn.
      destruct inn as [inn1 inn2].
      specialize (H _ inn1).
      elim (inn2 H).
    - rewrite fold_left_map.
      apply fold_left_ext. intros.
      rewrite remove_all_filter. trivial.
  Qed.

  Global Instance alg_ctxt_equiv_refl {refl:Reflexive base_equiv}: Reflexive alg_ctxt_equiv.
  Proof.
    unfold alg_ctxt_equiv.
    red; intros.
    - match_destr; reflexivity.
  Qed.   

  Global Instance alg_ctxt_equiv_sym {sym:Symmetric base_equiv}: Symmetric alg_ctxt_equiv.
  Proof.
    unfold alg_ctxt_equiv.
    red; intros.
    - specialize (H ps). match_destr; match_destr. symmetry. trivial.
  Qed.

  Global Instance alg_ctxt_equiv_trans {trans:Transitive base_equiv}: Transitive alg_ctxt_equiv.
  Proof.
    unfold alg_ctxt_equiv.
    red; intros.
    - specialize (H (ps ++ (map (fun x => (x, AID)) (ac_holes y)))).
      specialize (H0 (ps ++ (map (fun x => (x, AID)) (ac_holes y)))).
      repeat rewrite map_app in H, H0.
      rewrite (ac_substs_app x) in H.
      rewrite (ac_substs_app z) in H0.
      rewrite <- (ac_simplify_substs_simplify1
                    (ac_substs x ps)
                (map (fun x : nat => (x, ID)) (ac_holes y))) in H.
      rewrite <- (ac_simplify_substs_simplify1
                    (ac_substs z ps)
                    (map (fun x : nat => (x, ID)) (ac_holes y))) in H0.
      match_destr.
      match_destr.
      autorewrite with ac_substs in *; simpl in *.
      assert (nholes:ac_holes
               (ac_substs y
              (ps ++
                 (map (fun x : nat => (x, ID)) (ac_holes y)))) = nil).
      + simpl.
        rewrite ac_substs_holes_remove.
        rewrite fold_left_app.
        rewrite fold_left_map.
        simpl.
        case_eq (fold_left (fun (a1 : list nat) (b : nat) => remove_all b a1)
     (ac_holes y)
     (fold_left
        (fun (a1 : list nat) (b : nat * alg) =>
           remove_all (fst b) a1) ps (ac_holes y))); trivial.
        intros n rl fle.
        assert (inn:In n (n::rl)) by (simpl; intuition).
        rewrite <- fle in inn.
        generalize (fold_left_remove_all_nil_in_inv' inn); intros inn2.
        generalize (fold_left_remove_all_nil_in_not_inv' inn); intros nin2.
        apply fold_left_remove_all_nil_in_inv in inn2.
        intuition.
      + destruct (ac_simplify_nholes _ nholes) as [? eqq].
        rewrite eqq in H, H0.
        transitivity x0; trivial.
  Qed.

  Global Instance alg_ctxt_equiv_equivalence {equiv:Equivalence base_equiv}: Equivalence alg_ctxt_equiv.
  Proof.
    constructor; red; intros.
    - reflexivity.
    - symmetry; trivial.
    - etransitivity; eauto.
  Qed.

  Global Instance alg_ctxt_equiv_preorder {pre:PreOrder base_equiv} : PreOrder alg_ctxt_equiv.
  Proof.
    constructor; red; intros.
    - reflexivity.
    - etransitivity; eauto.
  Qed.

  Global Instance alg_ctxt_equiv_strict_refl {refl:Reflexive base_equiv}: Reflexive alg_ctxt_equiv_strict.
  Proof.
    red; intros.
    repeat rewrite <- alg_ctxt_equiv_strict_equiv in *.
    reflexivity.
  Qed.   

  Global Instance alg_ctxt_equiv_strict_sym {sym:Symmetric base_equiv}: Symmetric alg_ctxt_equiv_strict.
  Proof.
    red; intros.
    repeat rewrite <- alg_ctxt_equiv_strict_equiv in *.
    symmetry; trivial.
  Qed.   

  Global Instance alg_ctxt_equiv_strict_trans {trans:Transitive base_equiv}: Transitive alg_ctxt_equiv_strict.
  Proof.
    red; intros.
    repeat rewrite <- alg_ctxt_equiv_strict_equiv in *.
    etransitivity; eauto.
  Qed.
  
  Global Instance alg_ctxt_equiv_strict_equivalence {equiv:Equivalence base_equiv}: Equivalence alg_ctxt_equiv_strict.
  Proof.
    constructor; red; intros.
    - reflexivity.
    - symmetry; trivial.
    - etransitivity; eauto.
  Qed.

  Global Instance alg_ctxt_equiv_strict_preorder {pre:PreOrder base_equiv} : PreOrder alg_ctxt_equiv_strict.
  Proof.
    constructor; red; intros.
    - reflexivity.
    - etransitivity; eauto.
  Qed.


  Global Instance CPlug_proper :
    Proper (base_equiv ==> alg_ctxt_equiv) CPlug.
  Proof.
    unfold Proper, respectful.
    unfold alg_ctxt_equiv.
    intros. autorewrite with ac_substs.
    simpl; trivial.
  Qed.

  Global Instance CPlug_proper_strict :
    Proper (base_equiv ==> alg_ctxt_equiv_strict) CPlug.
  Proof.
    unfold Proper, respectful.
    unfold alg_ctxt_equiv_strict.
    intros. autorewrite with ac_substs.
    simpl; trivial.
  Qed.
  End equivs.
End RAlgContext.

(* TODO: show that the constructors of context are all proper with respect to context equivalence *)

Delimit Scope alg_ctxt_scope with alg_ctxt.

Notation "'ID'" := (CAID)  (at level 50) : alg_ctxt_scope.

Notation "‵‵ c" := (CAConst (dconst c))  (at level 0) : alg_ctxt_scope.                           (* ‵ = \backprime *)
Notation "‵ c" := (CAConst c)  (at level 0) : alg_ctxt_scope.                                     (* ‵ = \backprime *)
Notation "‵{||}" := (CAConst (dcoll nil))  (at level 0) : alg_ctxt_scope.                         (* ‵ = \backprime *)
Notation "‵[||]" := (CAConst (drec nil)) (at level 50) : alg_ctxt_scope.                          (* ‵ = \backprime *)

Notation "r1 ∧ r2" := (CABinop AAnd r1 r2) (right associativity, at level 65): alg_ctxt_scope.    (* ∧ = \wedge *)
Notation "r1 ∨ r2" := (CABinop AOr r1 r2) (right associativity, at level 70): alg_ctxt_scope.     (* ∨ = \vee *)
Notation "r1 ≐ r2" := (CABinop AEq r1 r2) (right associativity, at level 70): alg_ctxt_scope.     (* ≐ = \doteq *)
Notation "r1 ≤ r2" := (CABinop ALt r1 r2) (no associativity, at level 70): alg_ctxt_scope.     (* ≤ = \leq *)
Notation "r1 ⋃ r2" := (CABinop AUnion r1 r2) (right associativity, at level 70): alg_ctxt_scope.  (* ⋃ = \bigcup *)
Notation "r1 − r2" := (CABinop AMinus r1 r2) (right associativity, at level 70): alg_ctxt_scope.  (* − = \minus *)
Notation "r1 ♯min r2" := (CABinop AMin r1 r2) (right associativity, at level 70): alg_ctxt_scope. (* ♯ = \sharp *)
Notation "r1 ♯max r2" := (CABinop AMax r1 r2) (right associativity, at level 70): alg_ctxt_scope. (* ♯ = \sharp *)
Notation "p ⊕ r"   := ((CABinop AConcat) p r) (at level 70) : alg_ctxt_scope.                     (* ⊕ = \oplus *)
Notation "p ⊗ r"   := ((CABinop AMergeConcat) p r) (at level 70) : alg_ctxt_scope.                (* ⊗ = \otimes *)

Notation "¬( r1 )" := (CAUnop ANeg r1) (right associativity, at level 70): alg_ctxt_scope.        (* ¬ = \neg *)
Notation "ε( r1 )" := (CAUnop ADistinct r1) (right associativity, at level 70): alg_ctxt_scope.   (* ε = \epsilon *)
Notation "♯count( r1 )" := (CAUnop ACount r1) (right associativity, at level 70): alg_ctxt_scope. (* ♯ = \sharp *)
Notation "♯flatten( d )" := (CAUnop AFlatten d) (at level 50) : alg_ctxt_scope.                   (* ♯ = \sharp *)
Notation "‵{| d |}" := ((CAUnop AColl) d)  (at level 50) : alg_ctxt_scope.                        (* ‵ = \backprime *)
Notation "‵[| ( s , r ) |]" := ((CAUnop (ARec s)) r) (at level 50) : alg_ctxt_scope.              (* ‵ = \backprime *)
Notation "¬π[ s1 ]( r )" := ((CAUnop (ARecRemove s1)) r) (at level 50) : alg_ctxt_scope.          (* ¬ = \neg and π = \pi *)
Notation "p · r" := ((CAUnop (ADot r)) p) (left associativity, at level 40): alg_ctxt_scope.      (* · = \cdot *)

Notation "χ⟨ p ⟩( r )" := (CAMap p r) (at level 70) : alg_ctxt_scope.                              (* χ = \chi *)
Notation "⋈ᵈ⟨ e2 ⟩( e1 )" := (CAMapConcat e2 e1) (at level 70) : alg_ctxt_scope.                   (* ⟨ ... ⟩ = \rangle ...  \langle *)
Notation "r1 × r2" := (CAProduct r1 r2) (right associativity, at level 70): alg_ctxt_scope.       (* × = \times *)
Notation "σ⟨ p ⟩( r )" := (CASelect p r) (at level 70) : alg_ctxt_scope.                           (* σ = \sigma *)
Notation "r1 ∥ r2" := (CADefault r1 r2) (right associativity, at level 70): alg_ctxt_scope.       (* ∥ = \parallel *)
Notation "r1 ◯ r2" := (CAApp r1 r2) (right associativity, at level 60): alg_ctxt_scope.           (* ◯ = \bigcirc *)

Notation "$ n" := (CHole n) (at level 50)  : alg_ctxt_scope.

Notation "X ≡ₐ Y" := (alg_ctxt_equiv alg_eq X Y) (at level 90) : alg_ctxt_scope.

  Hint Rewrite
       @ac_substs_Plug
       @ac_substs_Binop
       @ac_substs_Unop
       @ac_substs_Map
       @ac_substs_MapConcat
       @ac_substs_Product
       @ac_substs_Select
       @ac_substs_Default
       @ac_substs_Either
       @ac_substs_EitherConcat
       @ac_substs_App : ac_substs.

(* 
*** Local Variables: ***
*** coq-load-path: (("../../../coq" "QCert")) ***
*** End: ***
*)
