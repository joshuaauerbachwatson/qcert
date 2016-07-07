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

Require Import List String.
Require Import Peano_dec.
Require Import EquivDec.

Require Import Utils BasicSystem.
Require Import NNRCRuntime ForeignToJava.
Require Import RType.
Require Import Sumbool.
Require Import ZArith.
Require Import Bool.
Require Import Utils.
Require Import BrandRelation.
Require Import ForeignData.
Require Import RData.

Require Import TDataInfer.
Require Import BrandRelation.
Require Import Utils Types BasicRuntime.
Require Import ForeignDataTyping.
Require Import NNRCtoJavascript.
Require Import JSON.


Section SparkData.

  Context {f:foreign_runtime}.
  Context {h:brand_relation_t}.
  Context {fttojs: ForeignToJavascript.foreign_to_javascript}.
  Context {ftype:foreign_type}.
  Context {fdtyping:foreign_data_typing}.
  Context {m:brand_model}.

  Section with_string_scope.
    Local Open Scope string_scope.

    Fixpoint rtype_to_scala (r: rtype₀) : string :=
      match r with
      | Bottom₀ => "NullType"
      | Top₀ => "StringType"
      | Unit₀ => "NullType"
      | Nat₀ => "IntegerType"
      | Bool₀ => "BooleanType"
      | String₀ => "StringType"
      | Coll₀ e => "ArrayType(" ++ rtype_to_scala e ++ ")"
      | Rec₀ _ fields =>
        let known_fields: list string :=
            map (fun p => "StructField(""" ++ fst p ++ """, " ++ rtype_to_scala (snd p) ++ ")")
                fields in
        let known_struct := "StructType(Seq(" ++ joinStrings ", " known_fields ++ ")" in
        "StructType(Seq(StructField(""$blob"", StringType), StructField(""$known"", " ++ known_struct ++ ")))"
      | Either₀ l r =>
        "StructType(Seq(StructField(""$left"", " ++ rtype_to_scala l ++ "), StructField(""$right"", " ++ rtype_to_scala r ++ ")))"
      | Brand₀ _ =>
        "StructType(Seq(StructField(""$data"", StringType), StructField(""$type"", ArrayType(StringType))))"
      (* should not occur *)
      | Arrow₀ _ _ => "ARROW TYPE?"
      | Foreign₀ ft => "FOREIGN TYPE?"
      end.

  End with_string_scope.

  Definition flip {a b c} (f : a -> b -> c) : b -> a -> c :=
    fun b a => f a b.

  Fixpoint data_to_blob (d: data): string :=
    dataToJS "\""" d.

  Lemma dataToJS_correctly_escapes_quote_inside_string:
    dataToJS """" (dstring "abc""cde") = """abc\""cde"""%string.
  Proof. vm_compute. Admitted. (* TODO I think dataToJS is broken.. *)

  Fixpoint typed_data_to_json (d: data) (r: rtype₀): option json :=
    match d, r with
    | _, Top₀ => Some (jstring (data_to_blob d))
    | dunit, Unit₀ => Some jnil
    | dnat i, Nat₀ => Some (jnumber i)
    | dbool b, Bool₀ => Some (jbool b)
    | dstring s, String₀ => Some (jstring s)
    | dcoll xs, (Coll₀ et) =>
      let listo := map (flip typed_data_to_json et) xs in
      lift jarray (listo_to_olist listo)
    | drec fs, Rec₀ Closed ft =>
      let fix convert_fields ds ts :=
          match ds, ts with
          | nil, nil => Some nil
          | nil, _ => None
          | _, nil => None
          | ((f, d)::ds), ((_, t)::ts) =>
            match typed_data_to_json d t, convert_fields ds ts with
            | Some json, Some tail => Some ((f, json)::tail)
            | _, _ => None
            end
          end in
      lift (fun fields => jobject (("$blob"%string, jstring "")
                                     :: ("$known"%string, jobject fields) :: nil))
           (convert_fields fs ft)
    | drec fs, Rec₀ Open ft =>
      (* Put typed fields in typed part, leftover fields in .. part *)
      let fix convert_known_fields ds ts us :=
          match ts, ds with
          (* No more typed fields, return leftover .. fields *)
          | nil, ds => Some (nil, us ++ ds)
          | _, nil => None
          | ((tf, t)::ts), ((df, d)::ds) =>
            if string_dec tf df
            then match typed_data_to_json d t, convert_known_fields ds ts us with
                 | Some json, Some (tail, us) => Some (((tf, json)::tail), us)
                 | _, _ => None
                 end
            else
              convert_known_fields ds ts ((df, d)::us)
          end in
      (* I'm not sure the dotdot fields are in the correct order, might need to sort them. *)
      match convert_known_fields fs ft nil with
      | Some (typed_fields, dotdot) =>
        Some (jobject (("$blob"%string, jstring (data_to_blob (drec dotdot)))
                         :: ("$known"%string, jobject typed_fields) :: nil))
      | None => None
      end
    | dleft l, Either₀ lt rt =>
      lift (fun l => jobject (("$left"%string, l)::("$right"%string, jnil)::nil))
           (typed_data_to_json l lt)
    | dright r, Either₀ lt rt =>
      lift (fun r => jobject (("$left"%string, jnil)::("$right"%string, r)::nil))
           (typed_data_to_json r rt)
    | dbrand bs v, Brand₀ bts =>
      (* Recursive brands are an issue. Solution: blob out the data in a brand. *)
      Some (jobject (("$data"%string, jstring (data_to_blob v))
                       :: ("$type"%string, jarray (map jstring bs)) :: nil))
    | _, _ => None
    end.

  Definition typed_data_to_json_string (d: data) (r: rtype): string :=
    match typed_data_to_json d (proj1_sig r) with
    | Some json => jsonToJS """" json
    | None => "typed_data_to_json_string failed. This cannot happen. Get rid of this case by proving that typed_data_to_json always succeeds for well-typed data."
    end.

  (* Added calls for integration within the compiler interface *)
  Require Import ForeignToJSON.
  Require Import JSON JSONtoData.

  Context {ftojson:foreign_to_JSON}.

  Definition data_to_sjson (d:data) (r:rtype) : option string :=
    (* Some (typed_data_to_json_string d r) *)
    lift (jsonToJS """") (typed_data_to_json d (proj1_sig r)).

End SparkData.

(*
*** Local Variables: ***
*** coq-load-path: (("../../coq" "QCert")) ***
*** End: ***
*)
