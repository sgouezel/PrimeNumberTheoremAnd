import Mathlib.Analysis.Distribution.SchwartzSpace
import Mathlib.MeasureTheory.Integral.IntegralEqImproper
import Mathlib.Topology.ContinuousFunction.Bounded
import Mathlib.Order.Filter.ZeroAndBoundedAtFilter
import Mathlib.Analysis.Fourier.Inversion

import PrimeNumberTheoremAnd.Mathlib.Analysis.Fourier.FourierTransformDeriv

open FourierTransform Real Complex MeasureTheory Filter Topology BoundedContinuousFunction SchwartzMap VectorFourier BigOperators

local instance {E : Type*} : Coe (E → ℝ) (E → ℂ) := ⟨fun f n => f n⟩

section lemmas

@[simp]
theorem nnnorm_eq_of_mem_circle (z : circle) : ‖z.val‖₊ = 1 := NNReal.coe_eq_one.mp (by simp)

@[simp]
theorem nnnorm_circle_smul (z : circle) (s : ℂ) : ‖z • s‖₊ = ‖s‖₊ := by
  simp [show z • s = z.val * s from rfl]

noncomputable def e (u : ℝ) : ℝ →ᵇ ℂ where
  toFun v := 𝐞 (-v * u)
  map_bounded' := ⟨2, fun x y => (dist_le_norm_add_norm _ _).trans (by simp [one_add_one_eq_two])⟩

@[simp] lemma e_apply (u : ℝ) (v : ℝ) : e u v = 𝐞 (-v * u) := rfl

theorem hasDerivAt_e {u x : ℝ} : HasDerivAt (e u) (-2 * π * u * I * e u x) x := by
  have l2 : HasDerivAt (fun v => -v * u) (-u) x := by simpa only [neg_mul_comm] using hasDerivAt_mul_const (-u)
  convert (hasDerivAt_fourierChar (-x * u)).scomp x l2 using 1
  simp ; ring

lemma fourierIntegral_deriv_aux2 (e : ℝ →ᵇ ℂ) {f : ℝ → ℂ} (hf : Integrable f) : Integrable (⇑e * f) :=
  hf.bdd_mul e.continuous.aestronglyMeasurable ⟨_, e.norm_coe_le_norm⟩

@[simp] lemma F_neg {f : ℝ → ℂ} {u : ℝ} : 𝓕 (fun x => -f x) u = - 𝓕 f u := by
  simp [fourierIntegral_eq, integral_neg]

@[simp] lemma F_add {f g : ℝ → ℂ} (hf : Integrable f) (hg : Integrable g) (x : ℝ) :
    𝓕 (fun x => f x + g x) x = 𝓕 f x + 𝓕 g x :=
  congr_fun (fourierIntegral_add continuous_fourierChar (by exact continuous_mul) hf hg).symm x

@[simp] lemma F_sub {f g : ℝ → ℂ} (hf : Integrable f) (hg : Integrable g) (x : ℝ) :
    𝓕 (fun x => f x - g x) x = 𝓕 f x - 𝓕 g x := by
  simp_rw [sub_eq_add_neg] ; rw [F_add] ; simp ; exact hf ; exact hg.neg

@[simp] lemma F_mul {f : ℝ → ℂ} {c : ℂ} {u : ℝ} : 𝓕 (fun x => c * f x) u = c * 𝓕 f u := by
  simp [fourierIntegral_real_eq, ← integral_mul_left] ; congr ; ext
  simp [Real.fourierChar, expMapCircle] ; ring

lemma contDiff_ofReal : ContDiff ℝ ⊤ ofReal' := by
  have key x : HasDerivAt ofReal' 1 x := hasDerivAt_id x |>.ofReal_comp
  have key' : deriv ofReal' = fun _ => 1 := by ext x ; exact (key x).deriv
  refine contDiff_top_iff_deriv.mpr ⟨fun x => (key x).differentiableAt, ?_⟩
  simpa [key'] using contDiff_const

end lemmas

section CS

variable {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] {n : ℕ}

@[ext] structure CS (n : ℕ) (E : Type*) [NormedAddCommGroup E] [NormedSpace ℝ E] where
  toFun : ℝ → E
  h1 : ContDiff ℝ n toFun
  h2 : HasCompactSupport toFun

@[ext] structure trunc extends (CS 2 ℝ) where
  h3 : (Set.Icc (-1) (1)).indicator 1 ≤ toFun
  h4 : toFun ≤ Set.indicator (Set.Ioo (-2) (2)) 1

instance : CoeFun (CS n E) (fun _ => ℝ → E) where coe := CS.toFun

instance : CoeFun trunc (fun _ => ℝ → ℝ) where coe f := f.toFun

instance : Coe trunc (CS 2 ℝ) where coe := trunc.toCS

instance : Coe (CS n ℝ) (CS n ℂ) where coe f := ⟨f,
  contDiff_ofReal.of_le le_top |>.comp f.h1, f.h2.comp_left (g := ofReal') rfl⟩

namespace trunc

variable (g : trunc)

lemma nonneg : 0 ≤ ⇑g := le_trans (Set.indicator_nonneg (by simp)) g.h3

lemma le_one : ⇑g ≤ 1 := g.h4.trans <| Set.indicator_le_self' (by simp)

lemma zero : g =ᶠ[𝓝 0] 1 := by
  have : Set.Icc (-1) 1 ∈ 𝓝 (0 : ℝ) := by apply Icc_mem_nhds <;> linarith
  exact eventually_of_mem this (fun x hx => le_antisymm (g.le_one x) (by simpa [hx] using g.h3 x))

end trunc

namespace CS

variable {f : CS n E} {R : ℝ} {v x : ℝ}

def neg (f : CS n E) : CS n E where
  toFun := -f
  h1 := f.h1.neg
  h2 := by simpa [HasCompactSupport, tsupport] using f.h2

instance : Neg (CS n E) where neg := neg

@[simp] lemma neg_apply {x : ℝ} : (-f) x = - (f x) := rfl

def smul (R : ℝ) (f : CS n E) : CS n E := ⟨R • f, f.h1.const_smul R, f.h2.smul_left⟩

instance : HSMul ℝ (CS n E) (CS n E) where hSMul := smul

@[simp] lemma smul_apply : (R • f) x = R • f x := rfl

lemma continuous (f : CS n E) : Continuous f := f.h1.continuous

noncomputable def deriv (f : CS (n + 1) E) : CS n E where
  toFun := _root_.deriv f
  h1 := (contDiff_succ_iff_deriv.mp f.h1).2
  h2 := f.h2.deriv

lemma hasDerivAt (f : CS (n + 1) E) (x : ℝ) : HasDerivAt f (f.deriv x) x :=
  (f.h1.differentiable (by simp)).differentiableAt.hasDerivAt

lemma deriv_apply {f : CS (n + 1) E} {x : ℝ} : f.deriv x = _root_.deriv f x := rfl

lemma deriv_smul {f : CS (n + 1) E} : (R • f).deriv = R • f.deriv := by
  ext x ; exact (f.hasDerivAt x |>.const_smul R).deriv

noncomputable def _root_.funscale (g : ℝ → E) (R x : ℝ) : E := g (R⁻¹ • x)

noncomputable def scale (g : CS n E) (R : ℝ) : CS n E := by
  by_cases h : R = 0
  · exact ⟨0, contDiff_const, by simp [HasCompactSupport, tsupport]⟩
  · refine ⟨fun x => funscale g R x, ?_, ?_⟩
    · exact g.h1.comp (contDiff_const.smul contDiff_id)
    · exact g.h2.comp_smul (inv_ne_zero h)

lemma deriv_scale {f : CS (n + 1) E} : (f.scale R).deriv = R⁻¹ • f.deriv.scale R := by
  ext v ; by_cases hR : R = 0 <;> simp [hR, scale]
  · simp [deriv, smul] ; exact deriv_const _ _
  · exact ((f.hasDerivAt (R⁻¹ • v)).scomp v (by simpa using (hasDerivAt_id v).const_smul R⁻¹)).deriv

lemma deriv_scale' {f : CS (n + 1) E} : (f.scale R).deriv v = R⁻¹ • f.deriv (R⁻¹ • v) := by
  rw [deriv_scale, smul_apply]
  by_cases hR : R = 0 <;> simp [hR, scale, funscale]

lemma hasDerivAt_scale (f : CS (n + 1) E) (R x : ℝ) :
    HasDerivAt (f.scale R) (R⁻¹ • _root_.deriv f (R⁻¹ • x)) x := by
  convert hasDerivAt (f.scale R) x ; rw [deriv_scale'] ; rfl

lemma bounded : ∃ C, ∀ v, ‖f v‖ ≤ C := by
  obtain ⟨x, hx⟩ := (continuous_norm.comp f.continuous).exists_forall_ge_of_hasCompactSupport f.h2.norm
  exact ⟨_, hx⟩

end CS

end CS

structure W21 where
  toFun : ℝ → ℂ
  hh : ContDiff ℝ 2 toFun
  hf : Integrable toFun
  hf' : Integrable (deriv toFun)
  hf'' : Integrable (deriv (deriv toFun))

instance : CoeFun W21 (fun _ => ℝ → ℂ) where coe := W21.toFun

namespace W21

variable {f : W21}

@[continuity] lemma continuous (f : W21) : Continuous f := f.hh.continuous

@[continuity] lemma continuous' (f : W21) : Continuous (deriv f) := (f.hh.iterate_deriv' 1 1).continuous

def sub (f g : W21) : W21 := by
  have l1 : deriv (⇑f - ⇑g) = deriv f - deriv g := by
    ext x ; apply deriv_sub
    · exact (f.hh.differentiable one_le_two).differentiableAt
    · exact (g.hh.differentiable one_le_two).differentiableAt
  have l2 : deriv (deriv (⇑f - ⇑g)) = deriv (deriv f) - deriv (deriv g) := by
    rw [l1] ; ext x ; apply deriv_sub
    · exact (f.hh.iterate_deriv' 1 1).differentiable le_rfl |>.differentiableAt
    · exact (g.hh.iterate_deriv' 1 1).differentiable le_rfl |>.differentiableAt
  refine ⟨f - g, f.hh.sub g.hh, f.hf.sub g.hf, ?_, ?_⟩
  · simpa [l1] using f.hf'.sub g.hf'
  · simpa [l2] using f.hf''.sub g.hf''

instance : HSub W21 W21 W21 where hSub := sub

noncomputable def norm (f : ℝ → ℂ) : ℝ :=
    (∫ v, ‖f v‖) + (4 * π ^ 2)⁻¹ * (∫ v, ‖deriv (deriv f) v‖)

lemma norm_nonneg {f : ℝ → ℂ} : 0 ≤ norm f :=
  add_nonneg (integral_nonneg (fun t => by simp))
    (mul_nonneg (by positivity) (integral_nonneg (fun t => by simp)))

noncomputable instance : Norm W21 where norm := norm ∘ toFun

noncomputable def of_Schwartz (f : 𝓢(ℝ, ℂ)) : W21 where
  toFun := f
  hh := f.smooth 2
  hf := f.integrable
  hf' := (SchwartzMap.derivCLM ℝ f).integrable
  hf'' := (SchwartzMap.derivCLM ℝ (SchwartzMap.derivCLM ℝ f)).integrable

noncomputable instance : Coe 𝓢(ℝ, ℂ) W21 where coe := of_Schwartz

def ofCS2 (f : CS 2 ℂ) : W21 where
  toFun := f
  hh := f.h1
  hf := f.h1.continuous.integrable_of_hasCompactSupport f.h2
  hf' := (f.h1.continuous_deriv one_le_two).integrable_of_hasCompactSupport f.h2.deriv
  hf'' := (f.h1.iterate_deriv' 0 2).continuous.integrable_of_hasCompactSupport f.h2.deriv.deriv

instance : Coe (CS 2 ℂ) W21 where coe := ofCS2

end W21

theorem fourierIntegral_self_add_deriv_deriv (f : W21) (u : ℝ) :
    (1 + u ^ 2) * 𝓕 f u = 𝓕 (fun u => f u - (1 / (4 * π ^ 2)) * deriv^[2] f u) u := by
  have l1 : Integrable (fun x => (((π : ℂ) ^ 2)⁻¹ * 4⁻¹) * deriv (deriv f) x) := (f.hf''.const_mul _)
  have l4 : Differentiable ℝ f := f.hh.differentiable one_le_two
  have l5 : Differentiable ℝ (deriv f) := (f.hh.iterate_deriv' 1 1).differentiable le_rfl
  simp [f.hf, l1, add_mul, Real.fourierIntegral_deriv f.hf' l5 f.hf'',
    Real.fourierIntegral_deriv f.hf l4 f.hf']
  field_simp [pi_ne_zero] ; ring_nf ; simp

instance : HMul (CS 2 ℂ) W21 (CS 2 ℂ) where hMul g f := ⟨g * f, g.h1.mul f.hh, g.h2.mul_right⟩

instance : HMul (CS 2 ℝ) W21 (CS 2 ℂ) where hMul g f := (g : CS 2 ℂ) * f

theorem W21_approximation (f : W21) (g : trunc) :
    Tendsto (fun R => ‖f - (g.scale R * f : W21)‖) atTop (𝓝 0) := by

  -- About f
  let f' := deriv f
  let f'' := deriv (deriv f)
  have cf'' : Continuous f'' := (f.hh.iterate_deriv' 0 2).continuous
  have df v : HasDerivAt f (f' v) v := f.hh.differentiable one_le_two |>.differentiableAt.hasDerivAt
  have df' v : HasDerivAt f' (f'' v) v := (f.hh.iterate_deriv' 1 1).differentiable le_rfl |>.differentiableAt.hasDerivAt

  -- About g
  let g' := (g : CS 2 ℝ).deriv
  let g'' := g'.deriv
  obtain ⟨c1, mg'⟩ := g'.bounded
  obtain ⟨c2, mg''⟩ := g''.bounded

  have evg' : g' =ᶠ[𝓝 0] 0 := by convert ← g.zero.deriv ; exact deriv_const' _
  have evg'' : g'' =ᶠ[𝓝 0] 0 := by convert ← evg'.deriv ; exact deriv_const' _

  -- About h
  let h R v := 1 - g.scale R v
  let h' R := - (g.scale R).deriv
  let h'' R := - (g.scale R).deriv.deriv
  have ch {R} : Continuous (fun v => (h R v : ℂ)) := continuous_ofReal.comp <| continuous_const.sub (CS.continuous _)
  have ch' {R} : Continuous (fun v => (h' R v : ℂ)) := continuous_ofReal.comp (CS.continuous _)
  have ch'' {R} : Continuous (fun v => (h'' R v : ℂ)) := continuous_ofReal.comp (CS.continuous _)
  have dh R v : HasDerivAt (h R) (h' R v) v := by
    convert CS.hasDerivAt_scale (g : CS 2 ℝ) R v |>.const_sub 1 using 1
    simp [h', CS.deriv_scale'] ; left ; rfl
  have dh' R v : HasDerivAt (h' R) (h'' R v) v := ((g.scale R).deriv.hasDerivAt v).neg
  have hc1 : ∀ᶠ R in atTop, ∀ v, |h' R v| ≤ c1 := by
    filter_upwards [eventually_ge_atTop 1] with R hR v
    have hR' : R ≠ 0 := by linarith
    have : 0 ≤ R := by linarith
    simp [h', CS.deriv_scale, abs_mul, abs_inv, abs_eq_self.mpr this] ; simp [CS.scale, funscale, hR']
    convert_to _ ≤ c1 * 1 ; simp ; rw [mul_comm]
    apply mul_le_mul (mg' _) (inv_le_of_inv_le (by linarith) (by simpa using hR)) (by positivity)
    exact (abs_nonneg _).trans (mg' 0)
  have hc2 : ∀ᶠ R in atTop, ∀ v, |h'' R v| ≤ c2 := by
    filter_upwards [eventually_ge_atTop 1] with R hR v
    have e1 : 0 ≤ R := by linarith
    have e2 : R⁻¹ ≤ 1 := inv_le_of_inv_le (by linarith) (by simpa using hR)
    have e3 : R ≠ 0 := by linarith
    simp [h'', CS.deriv_scale, CS.deriv_smul, abs_mul, abs_inv, abs_eq_self.mpr e1]
    convert_to _ ≤ 1 * (1 * c2) ; simp
    apply mul_le_mul e2 ?_ (by positivity) zero_le_one
    apply mul_le_mul e2 ?_ (by positivity) zero_le_one
    simp [CS.scale, e3, funscale] ; apply mg''

  have h0 R v : 0 ≤ h R v := by by_cases hR : R = 0 <;> simp [hR, h, CS.scale] ; exact g.le_one _
  have h1 R v : h R v ≤ 1 := by by_cases hR : R = 0 <;> simp [hR, h, CS.scale] ; exact g.nonneg _
  have hh1 R v : |h R v| ≤ 1 := by rw [abs_le] ; constructor <;> linarith [h0 R v, h1 R v]
  have vR v : Tendsto (fun R : ℝ => v * R⁻¹) atTop (𝓝 0) := by simpa using tendsto_inv_atTop_zero.const_mul v
  have eh v : ∀ᶠ R in atTop, h R v = 0 := by
    filter_upwards [(vR v).eventually g.zero, eventually_ne_atTop 0] with R hR hR'
    simp [h, hR, CS.scale, hR', funscale, mul_comm R⁻¹]
  have eh' v : ∀ᶠ R in atTop, h' R v = 0 := by
    filter_upwards [(vR v).eventually evg'] with R hR
    simp [g'] at hR
    simp [h', CS.deriv_scale', mul_comm R⁻¹, hR]
  have eh'' v : ∀ᶠ R in atTop, h'' R v = 0 := by
    filter_upwards [(vR v).eventually evg'', eventually_ne_atTop 0] with R hR hR'
    simp [h'', CS.deriv_scale, CS.deriv_smul, hR, hR']
    simp [CS.scale, hR', funscale, mul_comm R⁻¹]
    exact hR

  -- Computations
  have l16 R v : deriv (deriv (fun v => h R v * f v)) v = h'' R v * f v + 2 * h' R v * f' v + h R v * f'' v := by
    have l3 v : HasDerivAt (fun v => h R v * f v) (h' R v * f v + h R v * f' v) v := (dh R v).ofReal_comp.mul (df v)
    have l5 : HasDerivAt (fun v => h' R v * f v) (h'' R v * f v + h' R v * f' v) v := (dh' R v).ofReal_comp.mul (df v)
    have l7 : HasDerivAt (fun v => h R v * f' v) (h' R v * f' v + h R v * f'' v) v := (dh R v).ofReal_comp.mul (df' v)
    have d1 : deriv (fun v => h R v * f v) = fun v => h' R v * f v + h R v * f' v := funext (fun v => (l3 v).deriv)
    rw [d1] ; convert (l5.add l7).deriv using 1 ; ring

  -- Proof
  convert_to Tendsto (fun R => W21.norm (fun v => h R v * f v)) atTop (𝓝 0)
  · ext R ; change W21.norm _ = _ ; congr ; ext v ; simp [h, sub_mul] ; rfl
  rw [show (0 : ℝ) = 0 + ((4 * π ^ 2)⁻¹ : ℝ) * 0 by simp]
  refine Tendsto.add ?_ (Tendsto.const_mul _ ?_)
  · let F R v := ‖h R v * f v‖
    have e1 : ∀ᶠ (n : ℝ) in atTop, AEStronglyMeasurable (F n) volume := by
      apply eventually_of_forall ; intro R
      exact (ch.mul f.hh.continuous).norm.aestronglyMeasurable
    have e2 : ∀ᶠ (n : ℝ) in atTop, ∀ᵐ (a : ℝ), ‖F n a‖ ≤ ‖f a‖ := by
      apply eventually_of_forall ; intro R
      apply eventually_of_forall ; intro v
      simpa [F] using mul_le_mul (hh1 R v) le_rfl (by simp) zero_le_one
    have e4 : ∀ᵐ (a : ℝ), Tendsto (fun n ↦ F n a) atTop (𝓝 0) := by
      apply eventually_of_forall ; intro v
      apply tendsto_nhds_of_eventually_eq ; filter_upwards [eh v] with R hR ; simp [F, hR]
    simpa [F] using tendsto_integral_filter_of_dominated_convergence _ e1 e2 f.hf.norm e4
  · simp_rw [l16]
    let F R v := ‖h'' R v * f v + 2 * h' R v * f' v + h R v * f'' v‖
    let bound v := c2 * ‖f v‖ + 2 * c1 * ‖f' v‖ + ‖f'' v‖
    have e1 : ∀ᶠ (n : ℝ) in atTop, AEStronglyMeasurable (F n) volume := by
      apply eventually_of_forall ; intro R ; apply Continuous.aestronglyMeasurable
      exact (((ch''.mul f.continuous).add ((continuous_const.mul ch').mul f.continuous')).add (ch.mul cf'')).norm
    have e2 : ∀ᶠ (n : ℝ) in atTop, ∀ᵐ (a : ℝ), ‖F n a‖ ≤ bound a := by
      filter_upwards [hc1, hc2] with R hc1 hc2
      apply eventually_of_forall ; intro v ; specialize hc1 v ; specialize hc2 v
      simp only [F, bound, norm_norm]
      refine (norm_add_le _ _).trans ?_ ; apply add_le_add
      · refine (norm_add_le _ _).trans ?_ ; apply add_le_add <;> simp <;> gcongr
      · simpa using mul_le_mul (hh1 R v) le_rfl (by simp) zero_le_one
    have e3 : Integrable bound volume := (((f.hf.norm).const_mul _).add ((f.hf'.norm).const_mul _)).add f.hf''.norm
    have e4 : ∀ᵐ (a : ℝ), Tendsto (fun n ↦ F n a) atTop (𝓝 0) := by
      apply eventually_of_forall ; intro v
      refine tendsto_norm_zero.comp <| (ZeroAtFilter.add ?_ ?_).add ?_
      · apply tendsto_nhds_of_eventually_eq ; filter_upwards [eh'' v] with R hR ; simp [hR]
      · apply tendsto_nhds_of_eventually_eq ; filter_upwards [eh' v] with R hR ; simp [hR]
      · apply tendsto_nhds_of_eventually_eq ; filter_upwards [eh v] with R hR ; simp [hR]
    simpa [F] using tendsto_integral_filter_of_dominated_convergence bound e1 e2 e3 e4

@[simp] lemma deriv_ofReal : deriv ofReal' = fun _ => 1 := by
  ext x ; exact ((hasDerivAt_id x).ofReal_comp).deriv

theorem bla (a : ℂ) (f : ℝ → ℂ) (n : ℕ) (hf : ContDiff ℝ n f) :
    iteratedDeriv n (fun x ↦ a * x * f x) = fun x =>
      a * x * iteratedDeriv n f x + n * a * iteratedDeriv (n - 1) f x := by

  induction n with
  | zero => simp
  | succ n ih =>
    have l0 : ContDiff ℝ n f := hf.of_succ
    rw [iteratedDeriv_succ, ih l0] ; ext x
    have l5 : ContDiff ℝ (↑(1 + n)) f := by convert hf using 1 ; simp ; ring
    have l4 : DifferentiableAt ℝ (fun x ↦ iteratedDeriv n f x) x := by
      have := ((l5.iterate_deriv' 1 n).differentiable le_rfl).differentiableAt (x := x)
      simpa [iteratedDeriv_eq_iterate] using this
    have l3 : DifferentiableAt ℝ (fun x ↦ a * ↑x) x := by
      apply DifferentiableAt.const_mul
      exact (contDiff_ofReal.differentiable le_top).differentiableAt
    have l1 : DifferentiableAt ℝ (fun x ↦ a * ↑x * iteratedDeriv n f x) x := l3.mul l4
    have l2 : DifferentiableAt ℝ (fun x ↦ ↑n * a * iteratedDeriv (n - 1) f x) x := by
      apply DifferentiableAt.const_mul
      apply l5.differentiable_iteratedDeriv
      norm_cast ; exact Nat.sub_le _ _ |>.trans_lt (by simp)
    simp [deriv_add l1 l2, deriv_mul l3 l4, ← iteratedDeriv_succ]
    cases n <;> simp <;> ring

noncomputable def MS (a : ℂ) (f : 𝓢(ℝ, ℂ)) : 𝓢(ℝ, ℂ) where
  toFun x := a * x * f x
  smooth' := contDiff_const.mul contDiff_ofReal |>.mul f.smooth'
  decay' k n := by
    simp only [norm_iteratedFDeriv_eq_norm_iteratedDeriv]
    simp_rw [bla a f n <| f.smooth'.of_le le_top]
    obtain ⟨C₁, hC₁⟩ := f.decay' (k + 1) n
    obtain ⟨C₂, hC₂⟩ := f.decay' k (n - 1)
    use ‖a‖ * C₁ + ‖a‖ * n * C₂ ; intro x
    have l2 := norm_add_le (a * x * iteratedDeriv n f x) (n * a * iteratedDeriv (n - 1) f x)
    have l3 : 0 ≤ ‖x‖ ^ k := by positivity
    apply (mul_le_mul_of_nonneg_left l2 l3).trans ; rw [mul_add] ; apply add_le_add
    · have : 0 ≤ ‖a‖ := by positivity
      convert mul_le_mul_of_nonneg_left (hC₁ x) this using 1
      simp [norm_iteratedFDeriv_eq_norm_iteratedDeriv, abs_eq_self.mpr pi_nonneg] ; ring_nf ; rfl
    · have : 0 ≤ ‖a‖ * n := by positivity
      convert mul_le_mul_of_nonneg_left (hC₂ x) this using 1
      simp [norm_iteratedFDeriv_eq_norm_iteratedDeriv, abs_eq_self.mpr pi_nonneg] ; ring_nf ; rfl

@[simp] lemma MS_apply (a : ℂ) (f : 𝓢(ℝ, ℂ)) (x : ℝ) : MS a f x = (a * x) • f x := rfl

lemma MS_iterate (a : ℂ) (f : 𝓢(ℝ, ℂ)) (n : ℕ) : (MS a)^[n] f = fun x : ℝ => (a * x) ^ n • f x := by
  induction n generalizing f with
  | zero => simp
  | succ n ih => ext x ; simp [ih, pow_succ] ; ring

lemma fourierIntegral_decay_aux (f : ℝ → ℂ) (k : ℕ) (h1 : ContDiff ℝ k f)
    (h2 : ∀ n ≤ k, Integrable (iteratedDeriv n f)) (x : ℝ) :
    ‖(2 * π * I * x) ^ k • 𝓕 f x‖ ≤ (∫ y : ℝ, ‖iteratedDeriv k f y‖) := by
  have l2 (x : ℝ) : (2 * π * I * x) ^ k • 𝓕 f x = 𝓕 (iteratedDeriv k f) x := by
    simp [Real.fourierIntegral_iteratedDeriv h1 (fun n hn => h2 n <| Nat.cast_le.mp hn) le_rfl]
  simpa only [l2] using Fourier.norm_fourierIntegral_le_integral_norm ..

lemma iteratedDeriv_schwartz (f : 𝓢(ℝ, ℂ)) (n : ℕ) : iteratedDeriv n f = (SchwartzMap.derivCLM ℝ)^[n] f := by
  induction n with
  | zero => rfl
  | succ n ih => rw [iteratedDeriv_succ, ih, Function.iterate_succ'] ; rfl

theorem fourierIntegral_decay (f : 𝓢(ℝ, ℂ)) (k : ℕ) : ∃ C, ∀ (x : ℝ), ‖x‖ ^ k * ‖𝓕 f x‖ ≤ C := by
  convert_to ∃ C, ∀ x : ℝ, ‖x ^ k * 𝓕 f x‖ ≤ C ; · simp
  convert_to ∃ C, ∀ x : ℝ, ‖(2 * π * I * x) ^ k * 𝓕 f x‖ / (2 * π) ^ k ≤ C using 4
  · field_simp [mul_pow, abs_eq_self.mpr pi_nonneg] ; ring
  convert_to ∃ C, ∀ x : ℝ, ‖(2 * π * I * x) ^ k • 𝓕 f x‖ / (2 * π) ^ k ≤ C
  use (∫ (y : ℝ), ‖iteratedDeriv k (⇑f) y‖) / (2 * π) ^ k ; intro x
  have l1 : ∀ n ≤ k, Integrable (iteratedDeriv n f) volume := by
    simp_rw [iteratedDeriv_schwartz] ; simp [SchwartzMap.integrable]
  have := fourierIntegral_decay_aux f k (f.smooth'.of_le le_top) l1 x
  apply div_le_div_of_nonneg_right this (by positivity)

noncomputable def FS (f : 𝓢(ℝ, ℂ)) : 𝓢(ℝ, ℂ) where
  toFun := 𝓕 f
  smooth' := by
    rw [contDiff_top] ; intro n
    apply Real.contDiff_fourierIntegral ; intro k _
    apply SchwartzMap.integrable_pow_mul
  decay' := by
    simp only [norm_iteratedFDeriv_eq_norm_iteratedDeriv]
    intro k n
    have l1 (k : ℕ) (_ : k ≤ (n : ℕ∞)) : Integrable (fun x ↦ x ^ k • f x) volume := by
      convert_to Integrable ((MS 1)^[k] f) ; · simp [MS_iterate]
      apply SchwartzMap.integrable
    simp_rw [@Real.iteratedDeriv_fourierIntegral ℂ _ _ f n n l1 le_rfl]
    convert_to ∃ C, ∀ (x : ℝ), ‖x‖ ^ k * ‖𝓕 ((MS (-2 * π * I))^[n] f) x‖ ≤ C ; · simp [MS_iterate]
    apply fourierIntegral_decay

@[simp] lemma FS_apply (f : 𝓢(ℝ, ℂ)) (x : ℝ) : FS f x = 𝓕 f x := rfl

@[simp] lemma FS_toFun (f : 𝓢(ℝ, ℂ)) : ⇑(FS f) = 𝓕 f := rfl

@[simp] lemma schwarz_reduce (f : ℝ → ℂ) h1 h2 x : SchwartzMap.mk f h1 h2 x = f x := rfl

theorem fourierfourier {f : ℝ → ℂ} (hfi : Integrable f) (hfi' : Integrable (𝓕 f))
    (hfc : Continuous f) (x : ℝ) :
    𝓕 (𝓕 f) x = f (-x) := by
  rw [← MeasureTheory.Integrable.fourier_inversion (v := -x) hfi hfi' hfc.continuousAt]
  simp [fourierIntegralInv, Real.fourierIntegral, VectorFourier.fourierIntegral]

lemma FS4 (f : 𝓢(ℝ, ℂ)) : FS^[4] f = f := by
  have li0 : Integrable (⇑f) volume := f.integrable
  have li1 : Integrable (𝓕 ⇑f) := (FS f).integrable
  have li2 : Integrable (𝓕 (𝓕 ⇑f)) := (FS (FS f)).integrable
  have li3 : Integrable (𝓕 (𝓕 (𝓕 ⇑f))) volume := (FS (FS (FS f))).integrable
  have lc2 : Continuous (𝓕 (𝓕 ⇑f)) := (FS (FS f)).continuous
  ext x ; change 𝓕 (𝓕 (𝓕 (𝓕 f))) x = f x
  rw [fourierfourier li2 li3 lc2, fourierfourier li0 li1 f.continuous]
  simp
