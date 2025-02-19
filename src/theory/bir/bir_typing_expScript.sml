open HolKernel Parse boolLib bossLib;
open wordsTheory bitstringTheory;
open bir_auxiliaryTheory bir_immTheory bir_valuesTheory;
open bir_exp_immTheory bir_exp_memTheory bir_envTheory;
open bir_expTheory finite_mapTheory
open wordsLib pred_setTheory;

val _ = new_theory "bir_typing_exp";


(* ------------------------------------------------------------------------- *)
(*  Expressions                                                              *)
(* ------------------------------------------------------------------------- *)

val bir_val_ss = rewrites (type_rws ``:bir_val_t``);
val bir_type_ss = rewrites (type_rws ``:bir_type_t``);


val type_of_bir_exp_def = Define `
  (type_of_bir_exp (BExp_Const i) = SOME (BType_Imm (type_of_bir_imm i))) /\

  (type_of_bir_exp (BExp_MemConst aty vty mmap) = SOME (BType_Mem aty vty)) /\

  (type_of_bir_exp (BExp_Den v) = SOME (bir_var_type v)) /\

  (type_of_bir_exp (BExp_Cast ct e rty) = (case (type_of_bir_exp e) of
      NONE => NONE
    | SOME ty => (if (bir_type_is_Imm ty) then SOME (BType_Imm rty) else NONE))) /\

  (type_of_bir_exp (BExp_UnaryExp et e) = (case (type_of_bir_exp e) of
      NONE => NONE
    | SOME ty => (if (bir_type_is_Imm ty) then
        SOME ty else NONE))) /\

  (type_of_bir_exp (BExp_BinExp et e1 e2) = (case (type_of_bir_exp e1,
       type_of_bir_exp e2) of
       (SOME ty1, SOME ty2) => (if ((bir_type_is_Imm ty1) /\ (ty2 = ty1)) then SOME ty1 else NONE)
       | _, _ => NONE)) /\

  (type_of_bir_exp (BExp_BinPred pt e1 e2) = (case (type_of_bir_exp e1,
       type_of_bir_exp e2) of
       (SOME ty1, SOME ty2) => (if ((bir_type_is_Imm ty1) /\ (ty2 = ty1)) then SOME BType_Bool else NONE)
       | _, _ => NONE)) /\

  (type_of_bir_exp (BExp_MemEq e1 e2) = (case (type_of_bir_exp e1,
       type_of_bir_exp e2) of
       (SOME (BType_Mem aty1 vty1), SOME (BType_Mem aty2 vty2)) => (if ((aty2 = aty1) /\ (vty2 = vty1)) then SOME BType_Bool else NONE)
       | _, _ => NONE)) /\


  (type_of_bir_exp (BExp_IfThenElse ec e1 e2) = (case (type_of_bir_exp ec, type_of_bir_exp e1,
       type_of_bir_exp e2) of
       (SOME ect, SOME ty1, SOME ty2) => (if ((ect = BType_Bool) /\ (ty2 = ty1)) then SOME ty1 else NONE)
       | _, _, _ => NONE)) /\

  (type_of_bir_exp (BExp_Load me ae en rty) = (case (type_of_bir_exp me, type_of_bir_exp ae) of
       (SOME (BType_Mem aty vty), SOME (BType_Imm aty')) => (if (
            (aty = aty') /\ (if en = BEnd_NoEndian then (vty = rty) else (bir_number_of_mem_splits vty rty aty <> NONE))
           ) then SOME (BType_Imm rty) else NONE)
       | _, _ => NONE)) /\

  (type_of_bir_exp (BExp_Store me ae en v) = (case (type_of_bir_exp me, type_of_bir_exp ae, type_of_bir_exp v) of
       (SOME (BType_Mem aty vty), SOME (BType_Imm aty'), SOME (BType_Imm rty)) => (if (
            (aty = aty') /\ (if en = BEnd_NoEndian then (vty = rty) else (bir_number_of_mem_splits vty rty aty <> NONE))
           ) then SOME (BType_Mem aty vty) else NONE)
       | _, _, _ => NONE))`;


val type_of_bir_exp_THM = store_thm ("type_of_bir_exp_THM",
 ``!env e ty. (type_of_bir_exp e = SOME ty) ==>
              ((bir_eval_exp e env = NONE) \/ (?v. (bir_eval_exp e env = SOME v) /\ (type_of_bir_val v = ty)))``,

GEN_TAC >>
Induct >> (
  SIMP_TAC (list_ss++bir_val_ss) [bir_eval_exp_def, type_of_bir_exp_def,
     type_of_bir_val_def] >>
  REPEAT CASE_TAC
) >- (
  METIS_TAC[bir_env_read_types]
) >- (
  FULL_SIMP_TAC std_ss [bir_eval_cast_REWRS, bir_type_is_Imm_def] >>
  FULL_SIMP_TAC (std_ss++bir_val_ss) [type_of_bir_val_EQ_ELIMS, bir_eval_cast_REWRS,
    type_of_bir_gencast]
) >- (
  FULL_SIMP_TAC std_ss [bir_eval_unary_exp_REWRS, bir_type_is_Imm_def] >>
  FULL_SIMP_TAC (std_ss++bir_val_ss) [type_of_bir_val_EQ_ELIMS, bir_eval_unary_exp_REWRS,
    type_of_bir_unary_exp]
) >- (
  FULL_SIMP_TAC std_ss [bir_eval_bin_exp_REWRS, bir_type_is_Imm_def] >>
  FULL_SIMP_TAC (std_ss++bir_val_ss) [type_of_bir_val_EQ_ELIMS, bir_eval_bin_exp_REWRS,
    type_of_bir_bin_exp]
) >- (
  FULL_SIMP_TAC std_ss [bir_eval_bin_pred_REWRS, bir_type_is_Imm_def] >>
  FULL_SIMP_TAC (std_ss++bir_val_ss) [type_of_bir_val_EQ_ELIMS, bir_eval_bin_pred_REWRS,
    type_of_bir_val_def, BType_Bool_def, type_of_bool2b]
) >- (
  FULL_SIMP_TAC std_ss [bir_eval_memeq_REWRS, bir_type_is_Imm_def] >>
  FULL_SIMP_TAC (std_ss++bir_val_ss) [type_of_bir_val_EQ_ELIMS, bir_eval_memeq_REWRS,
    type_of_bir_val_def, BType_Bool_def, type_of_bool2b]
) >- (
  Cases_on `bir_eval_exp e env = NONE` >- (
    ASM_SIMP_TAC std_ss [bir_eval_ifthenelse_REWRS]
  ) >>
  FULL_SIMP_TAC std_ss [bir_eval_ifthenelse_REWRS, bir_type_is_Imm_def] >> 
  Cases_on `v` >>  Cases_on `v'` >> Cases_on `v''` >> (
    FULL_SIMP_TAC (std_ss++bir_val_ss) [type_of_bir_val_EQ_ELIMS, bir_eval_ifthenelse_REWRS,
      BType_Bool_def, type_of_bir_val_def] >>
    CASE_TAC
  ) >>
  FULL_SIMP_TAC (std_ss++bir_val_ss) [type_of_bir_val_EQ_ELIMS, bir_eval_ifthenelse_REWRS,
    BType_Bool_def, type_of_bir_val_def, type_of_bir_imm_def]
) >- (
  FULL_SIMP_TAC std_ss [bir_eval_load_NONE_REWRS] >>
  FULL_SIMP_TAC std_ss [type_of_bir_val_EQ_ELIMS, bir_eval_load_def] >>
  REPEAT GEN_TAC >> REPEAT CASE_TAC >> (
    METIS_TAC[type_of_bir_load_from_mem]
  )
) >- (
  FULL_SIMP_TAC std_ss [bir_eval_store_NONE_REWRS] >>
  FULL_SIMP_TAC std_ss [type_of_bir_val_EQ_ELIMS, bir_eval_store_def] >>
  REPEAT GEN_TAC >> REPEAT CASE_TAC
));


val type_of_bir_exp_EQ_SOME_REWRS = store_thm ("type_of_bir_exp_EQ_SOME_REWRS",``
  (!i ty. (type_of_bir_exp (BExp_Const i) = SOME ty) <=> (ty = BType_Imm (type_of_bir_imm i))) /\

  (!aty vty mmap ty. (type_of_bir_exp (BExp_MemConst aty vty mmap) = SOME ty) <=> (ty = BType_Mem aty vty)) /\

  (!v ty. (type_of_bir_exp (BExp_Den v) = SOME ty) <=> (ty = bir_var_type v)) /\

  (!ct e ty ty'. (type_of_bir_exp (BExp_Cast ct e ty') = SOME ty) <=> (
     (ty = BType_Imm ty') /\ (?it. (type_of_bir_exp e = SOME (BType_Imm it))))) /\

  (!et e ty. (type_of_bir_exp (BExp_UnaryExp et e) = SOME ty) <=> (
     (bir_type_is_Imm ty) /\ (type_of_bir_exp e = SOME ty))) /\

  (!et e1 e2 ty. (type_of_bir_exp (BExp_BinExp et e1 e2) = SOME ty) <=> (
     (bir_type_is_Imm ty) /\ (type_of_bir_exp e1 = SOME ty) /\ (type_of_bir_exp e2 = SOME ty))) /\

  (!pt e1 e2 ty. (type_of_bir_exp (BExp_BinPred pt e1 e2) = SOME ty) <=> (
     (ty = BType_Bool) /\ (?it. (type_of_bir_exp e1 = SOME (BType_Imm it)) /\
                              (type_of_bir_exp e2 = SOME (BType_Imm it))))) /\

  (!me1 me2 ty. (type_of_bir_exp (BExp_MemEq me1 me2) = SOME ty) <=> (
     ?at vt. (ty = BType_Bool) /\ (type_of_bir_exp me1 = SOME (BType_Mem at vt)) /\ (type_of_bir_exp me2 = type_of_bir_exp me1))) /\

  (!ce e1 e2 ty. (type_of_bir_exp (BExp_IfThenElse ce e1 e2) = SOME ty) <=> (
     (type_of_bir_exp ce = SOME BType_Bool) /\
     (type_of_bir_exp e1 = SOME ty) /\
     (type_of_bir_exp e2 = SOME ty))) /\

  (!rty ty ae en me. (type_of_bir_exp (BExp_Load me ae en rty) = SOME ty) <=> (
     (ty = BType_Imm rty) /\ (?at vt. (type_of_bir_exp me = SOME (BType_Mem at vt)) /\
                            (type_of_bir_exp ae = SOME (BType_Imm at)) /\
                            (if en = BEnd_NoEndian then (vt = rty) else
                                  (bir_number_of_mem_splits vt rty at <> NONE))))) /\

  (!ty ae en me v. (type_of_bir_exp (BExp_Store me ae en v) = SOME ty) <=> (
     ?at vt rty. (ty = BType_Mem at vt) /\
             (type_of_bir_exp me = SOME (BType_Mem at vt)) /\
             (type_of_bir_exp ae = SOME (BType_Imm at)) /\
             (type_of_bir_exp v = SOME (BType_Imm rty)) /\
             (if en = BEnd_NoEndian then (vt = rty) else
                                  (bir_number_of_mem_splits vt rty at <> NONE))))
``,

REPEAT CONJ_TAC >> (
  SIMP_TAC (std_ss++boolSimps.EQUIV_EXTRACT_ss) [type_of_bir_exp_def]
) >- (
  REPEAT GEN_TAC >> REPEAT CASE_TAC >>
    FULL_SIMP_TAC (std_ss++bir_type_ss) [bir_type_is_Imm_def] >> METIS_TAC[]
) >- (
  REPEAT GEN_TAC >> REPEAT CASE_TAC >> METIS_TAC[]
) >- (
  REPEAT GEN_TAC >> REPEAT CASE_TAC >> (
    FULL_SIMP_TAC std_ss [] >> METIS_TAC[]
  )
) >- (
  REPEAT GEN_TAC >> REPEAT CASE_TAC >> (
    FULL_SIMP_TAC std_ss [bir_type_is_Imm_def] >> METIS_TAC[]
  )
) >- (
  REPEAT GEN_TAC >> REPEAT CASE_TAC >> (
    FULL_SIMP_TAC (std_ss++bir_type_ss) [] >> METIS_TAC[]
  )
) >- (
  REPEAT GEN_TAC >> REPEAT CASE_TAC >> (
    FULL_SIMP_TAC std_ss [bir_type_is_Imm_def] >> METIS_TAC[]
  )
) >- (
  REPEAT GEN_TAC >> REPEAT CASE_TAC >> METIS_TAC[]
) >- (
  REPEAT GEN_TAC >> REPEAT CASE_TAC >> METIS_TAC[]
));



val type_of_bir_exp_EQ_NONE_REWRS = store_thm ("type_of_bir_exp_EQ_NONE_REWRS",``
  (!i. ~(type_of_bir_exp (BExp_Const i) = NONE)) /\

  (!aty vty mmap. ~(type_of_bir_exp (BExp_MemConst aty vty mmap) = NONE)) /\

  (!v. ~(type_of_bir_exp (BExp_Den v) = NONE)) /\

  (!ct e ty ty'. (type_of_bir_exp (BExp_Cast ct e ty') = NONE) <=> (
     (!ity. (type_of_bir_exp e <> SOME (BType_Imm ity))))) /\

  (!et e. (type_of_bir_exp (BExp_UnaryExp et e) = NONE) <=> (
     (!ity. type_of_bir_exp e <> SOME (BType_Imm ity)))) /\

  (!et e1 e2. (type_of_bir_exp (BExp_BinExp et e1 e2) = NONE) <=> !ity.
     (type_of_bir_exp e1 <> SOME (BType_Imm ity)) \/
     (type_of_bir_exp e2 <> SOME (BType_Imm ity))) /\

  (!pt e1 e2. (type_of_bir_exp (BExp_BinPred pt e1 e2) = NONE) <=> !ity.
     (type_of_bir_exp e1 <> SOME (BType_Imm ity)) \/
     (type_of_bir_exp e2 <> SOME (BType_Imm ity))) /\

  (!me1 me2. (type_of_bir_exp (BExp_MemEq me1 me2) = NONE) <=> !at vt.
     (type_of_bir_exp me1 <> SOME (BType_Mem at vt)) \/
     (type_of_bir_exp me2 <> SOME (BType_Mem at vt))) /\

  (!ce e1 e2 ty. (type_of_bir_exp (BExp_IfThenElse ce e1 e2) = NONE) <=> (
     (type_of_bir_exp ce <> SOME BType_Bool) \/
     (type_of_bir_exp e1 = NONE) \/
     (type_of_bir_exp e2 <> type_of_bir_exp e1))) /\

  (!rty ty ae en me. (type_of_bir_exp (BExp_Load me ae en rty) = NONE) <=> (
     (!at vt. (type_of_bir_exp me = SOME (BType_Mem at vt)) /\
              (type_of_bir_exp ae = SOME (BType_Imm at)) ==>
              (if en = BEnd_NoEndian then (vt <> rty) else
                   (bir_number_of_mem_splits vt rty at = NONE))))) /\

  (!ty ae en me v. (type_of_bir_exp (BExp_Store me ae en v) = NONE) <=> (
     !at vt rty.
             (type_of_bir_exp me = SOME (BType_Mem at vt)) /\
             (type_of_bir_exp ae = SOME (BType_Imm at)) /\
             (type_of_bir_exp v = SOME (BType_Imm rty)) ==>
             (if en = BEnd_NoEndian then (vt <> rty) else
                                  (bir_number_of_mem_splits vt rty at = NONE))))
``,

REPEAT CONJ_TAC >> (
  SIMP_TAC (std_ss++boolSimps.EQUIV_EXTRACT_ss) [type_of_bir_exp_def]
) >- (
  REPEAT GEN_TAC >> REPEAT CASE_TAC >> FULL_SIMP_TAC (std_ss++bir_type_ss) [bir_type_is_Imm_def]
) >- (
  REPEAT GEN_TAC >> REPEAT CASE_TAC >> FULL_SIMP_TAC (std_ss++bir_type_ss) [bir_type_is_Imm_def]
) >- (
  REPEAT GEN_TAC >> REPEAT CASE_TAC >> (
    FULL_SIMP_TAC (std_ss++bir_type_ss) [bir_type_is_Imm_def] >>
    METIS_TAC[]
  )
) >- (
  REPEAT GEN_TAC >> REPEAT CASE_TAC >> (
    FULL_SIMP_TAC (std_ss++bir_type_ss) [bir_type_is_Imm_def] >>
    METIS_TAC[]
  )
) >- (
  REPEAT GEN_TAC >> REPEAT CASE_TAC >> (
    FULL_SIMP_TAC (std_ss++bir_type_ss) [bir_type_is_Imm_def] >>
    METIS_TAC[]
  )
) >- (
  REPEAT GEN_TAC >> REPEAT CASE_TAC >> (
    FULL_SIMP_TAC (std_ss) []
  )
) >- (
  REPEAT GEN_TAC >> REPEAT CASE_TAC >> METIS_TAC[]
) >- (
  REPEAT GEN_TAC >> REPEAT CASE_TAC >> METIS_TAC[]
));


(* ------------------------------------------------------------------------- *)
(*  Looking at  variables used somewhere in an expression                    *)
(* ------------------------------------------------------------------------- *)

val bir_vars_of_exp_def = Define `
  (bir_vars_of_exp (BExp_Const _) = {}) /\
  (bir_vars_of_exp (BExp_MemConst _ _ _) = {}) /\
  (bir_vars_of_exp (BExp_Den v) = {v}) /\
  (bir_vars_of_exp (BExp_Cast _ e _) = bir_vars_of_exp e) /\
  (bir_vars_of_exp (BExp_UnaryExp _ e) = bir_vars_of_exp e) /\
  (bir_vars_of_exp (BExp_BinExp _ e1 e2) = (bir_vars_of_exp e1 UNION bir_vars_of_exp e2)) /\
  (bir_vars_of_exp (BExp_BinPred _ e1 e2) = (bir_vars_of_exp e1 UNION bir_vars_of_exp e2)) /\
  (bir_vars_of_exp (BExp_MemEq e1 e2) = (bir_vars_of_exp e1 UNION bir_vars_of_exp e2)) /\
  (bir_vars_of_exp (BExp_IfThenElse ec e1 e2) = (bir_vars_of_exp ec UNION bir_vars_of_exp e1 UNION bir_vars_of_exp e2)) /\
  (bir_vars_of_exp (BExp_Load me ae _ _) = (bir_vars_of_exp me UNION bir_vars_of_exp ae)) /\
  (bir_vars_of_exp (BExp_Store me ae _ ve) = (bir_vars_of_exp me UNION bir_vars_of_exp ae UNION bir_vars_of_exp ve))`;


val bir_vars_of_exp_THM = store_thm ("bir_vars_of_exp_THM",
``!env1 env2 e. (!v. v IN (bir_vars_of_exp e) ==>
                     (bir_env_read v env1 = bir_env_read v env2)) ==>
                (bir_eval_exp e env1 = bir_eval_exp e env2)``,

GEN_TAC >> GEN_TAC >> Induct >> REPEAT STRIP_TAC >> (
  FULL_SIMP_TAC std_ss [bir_vars_of_exp_def, pred_setTheory.IN_UNION,
    pred_setTheory.NOT_IN_EMPTY, pred_setTheory.IN_INSERT,
    bir_eval_exp_def]
));


val bir_vars_of_exp_THM_EQ_FOR_VARS = store_thm ("bir_vars_of_exp_THM_EQ_FOR_VARS",
``!env1 env2 e. (bir_env_EQ_FOR_VARS (bir_vars_of_exp e) env1 env2) ==>
                (bir_eval_exp e env1 = bir_eval_exp e env2)``,
METIS_TAC[bir_vars_of_exp_THM, bir_env_EQ_FOR_VARS_read_IMPL]);


val bir_vars_of_exp_FINITE = store_thm ("bir_vars_of_exp_FINITE",
``!e. FINITE (bir_vars_of_exp e)``,

Induct >> (
  ASM_SIMP_TAC std_ss [bir_vars_of_exp_def,
    pred_setTheory.FINITE_INSERT, pred_setTheory.FINITE_EMPTY,
    pred_setTheory.FINITE_UNION]
));


val type_of_bir_exp_THM_with_envty = store_thm ("type_of_bir_exp_THM_with_envty",
  ``!env envty e ty. (type_of_bir_exp e = SOME ty) ==>
                     (bir_envty_includes_vs envty (bir_vars_of_exp e)) ==>
                     (bir_env_satisfies_envty env envty) ==>
                     (?v. ((bir_eval_exp e env) = SOME v) /\ (type_of_bir_val v = ty))``,

GEN_TAC >> GEN_TAC >> Induct >> (
  SIMP_TAC (std_ss++bir_val_ss) [bir_eval_exp_def, BType_Bool_def,
    type_of_bir_exp_EQ_SOME_REWRS, bir_vars_of_exp_def,
    bir_envty_includes_vs_UNION, bir_envty_includes_vs_INSERT,
    bir_envty_includes_vs_EMPTY, PULL_EXISTS, PULL_FORALL, bir_type_is_Imm_def] >>
  REPEAT STRIP_TAC >>
  FULL_SIMP_TAC (std_ss++bir_val_ss) [type_of_bir_val_EQ_ELIMS, bir_type_is_Imm_def]
) >- (
  METIS_TAC [bir_v_in_envty_env_IMP]
) >- (
  SIMP_TAC (std_ss++bir_val_ss) [bir_eval_cast_REWRS, type_of_bir_gencast]
) >- (
  ASM_SIMP_TAC (std_ss++bir_val_ss) [bir_eval_unary_exp_REWRS, type_of_bir_unary_exp]
) >- (
  ASM_SIMP_TAC (std_ss++bir_val_ss) [bir_eval_bin_exp_REWRS, type_of_bir_bin_exp]
) >- (
  ASM_SIMP_TAC (std_ss++bir_val_ss) [bir_eval_bin_pred_REWRS, type_of_bir_val_def,
    type_of_bool2b, BType_Bool_def]
) >- (
  ASM_SIMP_TAC (std_ss++bir_val_ss) [bir_eval_memeq_REWRS, type_of_bir_val_def,
    type_of_bool2b, BType_Bool_def]
) >- (
  ASM_SIMP_TAC (std_ss++bir_val_ss) [bir_eval_ifthenelse_REWRS] >>
  METIS_TAC[]
) >- (
  ASM_SIMP_TAC (std_ss++bir_val_ss) [bir_eval_load_BASIC_REWR] >>
  rename1 `bir_load_from_mem vt ity at mmap en (b2n i)` >>
  Cases_on `bir_load_from_mem vt ity at mmap en (b2n i)` >- (
    POP_ASSUM MP_TAC >>
    ASM_SIMP_TAC (std_ss++bir_val_ss) [bir_load_from_mem_EQ_NONE] >>
    Cases_on `en = BEnd_NoEndian` >> (
       FULL_SIMP_TAC (std_ss++boolSimps.CONJ_ss) [bir_number_of_mem_splits_ID]
    )
  ) >>
  ASM_SIMP_TAC (std_ss++bir_val_ss) [] >>
  METIS_TAC [type_of_bir_load_from_mem]
) >- (
  ASM_SIMP_TAC (std_ss++bir_val_ss) [bir_eval_store_BASIC_REWR] >>
  rename1 `bir_store_in_mem vt at ity mmap en (b2n i)` >>
  Cases_on `bir_store_in_mem vt at ity mmap en (b2n i)` >- (
    POP_ASSUM MP_TAC >>
    ASM_SIMP_TAC (std_ss++bir_val_ss) [bir_store_in_mem_EQ_NONE] >>
    Cases_on `en = BEnd_NoEndian` >> (
       FULL_SIMP_TAC (std_ss++boolSimps.CONJ_ss) [bir_number_of_mem_splits_ID]
    )
  ) >>
  ASM_SIMP_TAC (std_ss++bir_val_ss) []
));

(* TODO: move elsewhere *)
open bir_env_oldTheory;
val type_of_bir_exp_THM_with_init_vars = store_thm ("type_of_bir_exp_THM_with_init_vars",
  ``!env e ty. (type_of_bir_exp e = SOME ty) ==>
               (bir_env_vars_are_initialised env (bir_vars_of_exp e)) ==>
               (?va. (bir_eval_exp e env = SOME va) /\ (type_of_bir_val va = ty))``,
  METIS_TAC [type_of_bir_exp_THM_with_envty, bir_env_vars_are_initialised_EQ_envty, bir_env_satisfies_envty_of_env]
);


(* -------------------- *)
(* Sensible expressions *)
(* -------------------- *)

(* A sensible expression should be well-typed, i.e. expressions
   like "BExp_BinPred BIExp_And (BExp_Const (Imm1 1w)) (BExp_Const (Imm8 3w))"
   should not be used.

   More subtly, one needs also make sure that variables occuring in the expression
   are having consistent type annotations. This is expressed as follows: *)

val bir_exp_is_well_typed_def = Define `bir_exp_is_well_typed e <=>
  (IS_SOME (type_of_bir_exp e) /\
   bir_vs_consistent (bir_vars_of_exp e))`




val _ = export_theory();
