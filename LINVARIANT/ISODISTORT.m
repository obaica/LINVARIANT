BeginPackage["LINVARIANT`ISODISTORT`",{"LINVARIANT`Structure`","LINVARIANT`GroupTheory`"}]

(*--------- Load, Save and Modify Crystal Structure Libraries ------------*)
ShowIsoModes                 ::usage = "ShowIsoModes[PosVec]"
GetIsoBasis                  ::usage = "GetIsoBasis[grp0, Wyckoff0]"
GetSymAdaptedBasis           ::usage = "GetSymAdaptedBasis[grp0, pos, kpoint, ftype, ct0]"
ISODISTORT                   ::usage = "ISODISTORT[R0, pos0, pos, IsoMatrix, label]"
ImposeMode                   ::usage = "ImposeMode[Wyckoff0, IsoMatrix, modeset, s]"
GetIRvector                  ::usage = "GetIRvector[id, pos]"
GetBasisField                ::usage = "GetBasisField[id, BasisMatrix, pos]"
GetOpMatrix                  ::usage = "GetOpMatrix[SymOpFile, pos, IsoMatrix, Modes]"
GetMatrixRep                 ::usage = "GetMatrixRep[SymOpFile, pos, IsoMatrix, Modes]"
SymmetryOpBasisField         ::usage = "SymmetryOpBasisField[grp, BasisField]"
GetIsoVars                   ::usage = "GetIsoVars[IsoDispModes]"
GetIsoTransformRules         ::usage = "GetIsoDispTransformRules[OpMatrix, IsoDispModes, TranType]"
GetIsoStrainTransformRules   ::usage = "GetIsoStrainTransformRules[GridSymFile]"
Epsilon2Field                ::usage = "Epsilon2Field[strain]"
Field2Epsilon                ::usage = "Field2Epsilon[field]"
GetEpsilonijRule             ::usage = "GetEpsilonijRule[symfile]"
GetTransformationRules       ::usage = "GetTransformationRules[spg0, OpDispModes, OpDispMatrix, SpinModes, OpSpinMatrix]"
GetInvariants                ::usage = "GetInvariants[seeds, order, AllModes, OpMatrix, GridSymFile]"
NumberCommonDivisor          ::usage = "NumberCommonDivisor[NumList]"
GetConstantFactor            ::usage = "GetConstantFactor[expr]"
SimplifyCommonFactor         ::usage = "SimplifyCommonFactor[expr]"
ImposeDW                     ::usage = "ImposeDW[Wyckoff0, IsoMatrix, modeset, {Nx, Ny, Nz}]"
ImposeIsoStrainVariedDspMode ::usage = "ImposeIsoStrainVariedDspMode[Wyckoff0, IsoMatrix, modeset, LV]"
ShowInvariantTable           ::usage = "ShowInvariantTable[TableData]"
Jij                          ::usage = "Jij[r0, MeshDim]"
FieldCode2var                ::usage = "FieldCode2var[code, varstr]"
GetSiteInt                   ::usage = "GetSiteInt[spg0, field]"
GetSiteCluster               ::usage = "GetSiteCluster[spg0, PosVec]"
InvariantEOnSite             ::usage = "InvariantEOnSite[xyz, expr]"

(*--------- Plot and Manipulate Crystal Structures -------------------- ----------------*)

(*--------- Point and Space Group Information ---------------------------*)

(*--------------------------------------------------*)
(*-------------------------- Internal --------------*)
Epsilon
(*--------------------------------------------------*)

(*--------------------------- Options ----------------------------*)
(*Options[ImportIsodistortCIF]    = {Fractional->False, CorrectLabels->True, Tolerance->10^-6}*)

(*--------------------------- external Modules -------------------*)

Begin["`Private`"]

(*--------------------------- Modules ----------------------------*)
ShowIsoModes[PosVec_] := Module[{StructData},
  StructData = Table[{ElementData[i[[3]], "IconColor"], 
                      Sphere[i[[1]], QuantityMagnitude[ElementData[i[[3]], "AtomicRadius"], "Angstroms"]/2], 
                      Black, 
                      Text[i[[3]]<>ToString@Position[PosVec, i][[1, 1]], 
                      i[[1]]]}, {i, PosVec}];

  ArrowData = Table[{Green, 
                     Arrowheads[0.03], 
                     Arrow@Tube[{i[[1]], 
                     i[[1]] + i[[2]]}]}, {i, PosVec}];

  Print[Graphics3D[{StructData, ArrowData}, 
                   ImageSize -> 500, 
                   Axes -> True, 
                   AxesLabel -> (Style[#, Bold, 64]&/@{"a", "b", "c"}), 
                   ViewPoint -> {0, 0, \[Infinity]}]];
]

ISODISTORT[R0_, pos0_, pos_, IsoMatrix_, label_] := Module[{imode, Amp, NN, posmatched},
  posmatched = Transpose[{PosMatchTo[pos0\[Transpose][[1]], pos\[Transpose][[1]], 0.01][[2]], Transpose[pos0][[2]]}];
  Amp = Table[Flatten[R0.PbcDiff[#] & /@ (Transpose[posmatched][[1]] - Transpose[pos0][[1]])].Normalize@Normal[IsoMatrix[[;; , imode]]], {imode, Length@label}];
  NN = Table[1/Norm@Flatten[R0.# & /@ Partition[Normal[IsoMatrix][[;; , imode]], 3]], {imode, Length@label}];
  Return[{Range[Length@label], label, NN, Chop[Amp, 2 10^-4]}\[Transpose]]
]

ImposeMode[Wyckoff0_, IsoMatrix_, modeset_, s_] := Module[{mode, id, Amp, pos},
  pos = Wyckoff0;
  Do[id = mode[[1]]; Amp = s mode[[3]] mode[[4]];
     pos = Transpose[{#[[1]] & /@ pos + Amp If[IntegerQ[id], # & /@ Partition[IsoMatrix[[;; , id]] // Normal, 3], Print["mode not exist!"]], First@StringCases[#,RegularExpression["[[:upper:]][[:lower:]]*"]] & /@ Transpose[pos][[2]]}], {mode, modeset}];
  Return[pos]
]

(*Jij[spg0_, OptionsPattern[{"Cluster" -> False}]] := Module[{tij, i, j}, 
  tij = DeleteDuplicates[DeleteCases[Flatten[Table[Total[Rationalize[#1[[2]]].{Subscript[Iso, 1, #1[[1]][[1]], #1[[1]][[2]], #1[[1]][[3]]], Subscript[Iso, 2, #1[[1]][[1]], #1[[1]][[2]], #1[[1]][[3]]], Subscript[Iso, 3, #1[[1]][[1]], #1[[1]][[2]], #1[[1]][[3]]]} Rationalize[#2[[2]]].{Subscript[Iso, 1, #2[[1]][[1]], #2[[1]][[2]], #2[[1]][[3]]], Subscript[Iso, 2, #2[[1]][[1]], #2[[1]][[2]], #2[[1]][[3]]], Subscript[Iso, 3, #2[[1]][[1]], #2[[1]][[2]], #2[[1]][[3]]]} & @@@
  ({Flatten[GetSiteCluster[spg0, {{{0, 0, 0}, v1}}, "spin" -> False], 1], Flatten[GetSiteCluster[spg0, {{neighbor, v2}}, "spin" -> False], 1]}\[Transpose])], {v1, IdentityMatrix[3]}, {v2, IdentityMatrix[3]}, {neighbor, Flatten[GetUpTo3rdNeighbors[], 1]}]], 0], #1 === -#2 || #1 === #2 &];
  Return[Table[Expand[tij[[j]]/(GCD @@ Table[tij[[j]][[i]] /. {Subscript[Iso, i_, x_, y_, z_] -> 1}, {i, Length@tij[[j]]}])], {j, Length@tij}]]
]*)

Jij[spg0_, fielddef_?ListQ, OptionsPattern[{"OnSite" -> False, "IsoTranRules"->{}}]] := Module[{tij, i, j, field, v0, v1, neighbor},
  Which[Length@Dimensions[fielddef] == 2,
        tij = Expand[DeleteDuplicates[DeleteCases[Flatten[
           Table[
                 field = {{fielddef[[1,1]], {{0, 0, 0}, v0}, fielddef[[1,3]]}, {fielddef[[2,1]], {neighbor, v1}, fielddef[[2,3]]}};
                 GetSiteInt[spg0, field, "IsoTranRules"->OptionValue["IsoTranRules"]], {v0, fielddef[[1,2]]}, {v1, fielddef[[2,2]]}, {neighbor, Flatten[GetUpTo3rdNeighbors["OnSite" -> OptionValue["OnSite"]], 1]}
                 ]
        ], 0], #1 === -#2 || #1 === #2 &]];
        Return[Expand[#/GCD @@ (If[MatchQ[#, Plus[_, __]], Level[#, {1}], Level[#, {0}]] /. Thread[Variables[#] -> ConstantArray[1, Length[Variables[#]]]])] & /@ tij],
        Length@Dimensions[fielddef] > 2,
        Flatten[Jij[spg0, #, "OnSite" -> OptionValue["OnSite"], "IsoTranRules"->OptionValue["IsoTranRules"]] &/@ fielddef]
      ]
]

Epsilon2Field[strain_] := Module[{}, 
  {{{0, 0, 0}, IdentityMatrix[3][[strain[[2]]]]}, {IdentityMatrix[3][[strain[[3]]]], IdentityMatrix[3][[strain[[2]]]]}, {{0, 0, 0}, IdentityMatrix[3][[strain[[3]]]]}, {IdentityMatrix[3][[strain[[2]]]], IdentityMatrix[3][[strain[[3]]]]}}]

Field2Epsilon[field_] := Module[{}, 
  1/2 (Sum[Normalize[field[[2]][[1]]][[j]] Normalize[field[[1]][[2]]][[i]] Subscript[Epsilon, i, j], {j, 3}, {i, 3}] + Sum[Normalize[field[[4]][[1]]][[j]] Normalize[field[[3]][[2]]][[i]] Subscript[Epsilon, i, j], {j, 3}, {i, 3}])/.{Subscript[Epsilon, 2, 1] -> Subscript[Epsilon, 1, 2], Subscript[Epsilon, 3, 1] -> Subscript[Epsilon, 1, 3], Subscript[Epsilon, 3, 2] -> Subscript[Epsilon, 2, 3]}]

(*Epsilon2Field[strain_] := Module[{},
  {{{0, 0, 0}, IdentityMatrix[3][[strain[[2]]]]}, {IdentityMatrix[3][[strain[[3]]]], IdentityMatrix[3][[strain[[2]]]]}}
]

Field2Epsilon[field_] := Module[{},
  Sum[Normalize[field[[2]][[1]]][[j]] Normalize[field[[1]][[2]]][[i]] Subscript[Epsilon, i, j], {j, 3}, {i, 3}] /. {Subscript[Epsilon, 2, 1] -> Subscript[Epsilon, 1, 2], Subscript[Epsilon, 3, 1] -> Subscript[Epsilon, 1, 3], Subscript[Epsilon, 3, 2] -> Subscript[Epsilon, 2, 3]}
]*)

GetEpsilonijRule[spg0_] := Module[{tij, i},
  strains = DeleteDuplicates@Flatten[SparseArray[{{i_, j_} /; i == j -> Subscript[Epsilon, i, j], {i_, j_} /; i < j -> Subscript[Epsilon, i, j], {i_, j_} /; i > j -> Subscript[Epsilon, j, i]}, {3, 3}] // Normal];
  Thread[strains -> #] & /@ (Table[Field2Epsilon[#] & /@ GetSiteCluster[spg0, Epsilon2Field[ep], "disp"], {ep, strains}]\[Transpose])
]

GetIsoVars[IsoDispModes_] := Module[{VarString, Var},
  VarString = {#1 & @@@ IsoDispModes, StringReplace[First@StringCases[#2, RegularExpression["[[:upper:]]*\\d[+-]"]], {"+" -> "Plus", "-" -> "Minus"}] & @@@ IsoDispModes, StringPart[#2, -2] & @@@ IsoDispModes}\[Transpose];
  Var = {#1, Subscript[ToExpression[#2], ToExpression[#3]]} & @@@ VarString;
  Return[Var]
]

GetIRvector[id_, IsoMatrix_, pos_] := Module[{IRvector},
  IRvector = {If[IntegerQ[id], # & /@ Partition[IsoMatrix[[;; , id]] // Normal, 3], Print["mode not exist!"]], # & /@ (pos\[Transpose][[2]])}\[Transpose];
  Return[IRvector]
]

GetBasisField[id_, BasisMatrix_, BasisLabels_, pos_, ftype_] := Module[{BasisLabelsupdn, BasisField, latt, sites, i, j, lm, p, p0, dim},
  {latt, sites} = pos;
  BasisField = Which[ListQ[id], 
                     GetBasisField[#, BasisMatrix, BasisLabels, pos, ftype] & /@ id, 
                     IntegerQ[id], 
                     If[ftype!="orbital",
                        {sites\[Transpose][[2]], 
                        {sites\[Transpose][[1]], Partition[Normal[BasisMatrix][[;; , id]], 3]}\[Transpose], 
                        ConstantArray[ftype, Length[sites]]}\[Transpose],
                        (*ftype=="orbital"*)
                        BasisLabelsupdn = Join[BasisLabels, BasisLabels];
                        sites = Join[sites, sites];
                        dim = Total@Flatten[Table[2 # + 1 &/@ lm, {lm, BasisLabelsupdn}]];
                        If[dim != Length[BasisMatrix], 
                           Print["Error: Basis Matrix dimension mismatch!!!"];Abort[]];
                        p0 = 1;
                        Table[{sites[[i,2]],
                               {sites[[i,1]],
                               Table[p = p0; p0 = p0 + 2*lm +1;
                                     BasisMatrix[[p;;p+2*lm,id]], {lm, BasisLabelsupdn[[i]]}]}, 
                               If[i<=Length[sites]/2, "up","dn"]}, {i, Length@BasisLabelsupdn}]
                
                        ]
                    ];
  Return[BasisField]
]

GetOpMatrix[grp_, pos_, IsoMatrix_, Modes_, ftype_] := Module[{latt, sites, op2, ir1, ir2, mat, OpMatrix, AllIRvectors, AllTransformedIRvectors, NormFactor, IsoDim, i, vec},
  {latt, sites} = pos;
  IsoDim = Length@Modes;

  Which[AssociationQ[grp],
        If[IsoDim != 0,
        {NormFactor, AllIRvectors} = Table[
                    vec=GetIRvector[i, IsoMatrix, sites]\[Transpose][[1]];
                    {1/Norm[Flatten[vec]], vec}, {i, IsoDim}]\[Transpose];
        AllTransformedIRvectors = Transpose[ParallelTable[SymmetryOpVectorField[grp, sites, GetIRvector[id, IsoMatrix, sites], ftype], {id, IsoDim}, DistributedContexts -> {"LINVARIANT`ISODISTORT`Private`"}]];
        ParallelTable[
          mat=Table[Rationalize[NormFactor[[ir1]]*NormFactor[[ir2]]*Flatten[op2[[ir1]]\[Transpose][[1]]].Flatten[AllIRvectors[[ir2]]]], {ir1, Range@IsoDim}, {ir2, Range@IsoDim}]; 
          SparseArray[mat], {op2, AllTransformedIRvectors}, DistributedContexts -> {"LINVARIANT`ISODISTORT`Private`"}], Table[{{}}, {Length@grp}]],
        ListQ[grp],
        OpMatrix = GetOpMatrix[#, pos, IsoMatrix, Modes, ftype] &/@ grp;
        If[IsoDim != 0,
           Fold[Dot, #] &/@ Tuples[OpMatrix],
           Table[{{}}, Fold[Times, Length[#] &/@ OpMatrix]]]
  ]
]

GetMatrixRep[grp_, pos_, BasisMatrix_, BasisLabels_, ftype_] := Module[{i, op, op2, ir1, ir2, mat, OpMatrix, AllIRvectors, BasisField, TransformedBasisField, BasisDim, g, ig, field, NormFactor, latt, sites, basis},
  {latt, sites} = pos;
  BasisDim = Length@BasisMatrix;

  Which[AssociationQ[grp],
        If[BasisDim != 0,
        {NormFactor, BasisField} = If[ftype != "orbital",
        Table[basis=GetBasisField[i, BasisMatrix, BasisLabels, pos, ftype];
           {1/Norm[Flatten[basis\[Transpose][[2]]\[Transpose][[2]]]], basis}, {i,BasisDim}]\[Transpose],
        (* ftype == orbital *)
        Table[basis=GetBasisField[i, BasisMatrix, BasisLabels, pos, ftype];
           {1/Norm[Flatten[basis\[Transpose][[2]]\[Transpose][[2]]]], basis}, {i,BasisDim}]\[Transpose]];
        TransformedBasisField = ParallelTable[SymmetryOpBasisField[g, pos, #, ftype] &/@ BasisField, {g, Keys@grp}, DistributedContexts -> {"LINVARIANT`ISODISTORT`Private`"}];
        ParallelTable[mat = Table[Rationalize[NormFactor[[i]]*NormFactor[[j]]*Flatten[TransformedBasisField[[ig]][[i]]\[Transpose][[2]]\[Transpose][[2]]].Flatten[BasisField[[j]]\[Transpose][[2]]\[Transpose][[2]]]], {i, Range@BasisDim}, {j, Range@BasisDim}];
        SparseArray[mat], {ig, Length@grp}, DistributedContexts -> {"LINVARIANT`ISODISTORT`Private`"}], 
        Table[{}, {Length@grp}]],
        ListQ[grp],
        OpMatrix = GetMatrixRep[#, pos, BasisMatrix, BasisLabels, ftype] &/@ grp;
        If[BasisDim != 0,
           Fold[Dot, #] &/@ Tuples[OpMatrix],
           Table[{{}}, Fold[Times, Length[#] &/@ OpMatrix]]]
  ]
]
 
SymmetryOpBasisField[grp_, pos_, BasisField_, ftype_] := Module[{latt, sites, site, i, xyzRotTran, xyzTrans, xyzRot, NewField, NewFieldup, NewFielddn, posvec, difftable, posmap, updn, updnbasis, upbasis, dnbasis},
  Which[
   AssociationQ[grp],
   SymmetryOpBasisField[#, pos, BasisField, ftype] & /@ Keys[grp],
   ListQ[grp] && ! MatrixQ[grp],
   SymmetryOpBasisField[#, pos, BasisField, ftype] & /@ grp,
   MatrixQ[grp],
   SymmetryOpBasisField[M42xyzStr[grp], pos, BasisField, ftype],
   StringQ[grp] && Length[Dimensions[BasisField]] == 3,
   SymmetryOpBasisField[grp, pos, #, ftype] & /@ BasisField,
   StringQ[grp] && Length[Dimensions[BasisField]] == 2,
   {latt, sites} = pos;
   xyzRotTran = ToExpression["{" <> grp <> "}"];
   xyzTrans = xyzRotTran /. {ToExpression["x"] -> 0, ToExpression["y"] -> 0, ToExpression["z"] -> 0};
   xyzRot = xyzRotTran - xyzTrans;
   If[ftype!="orbital",
     Which[
       ftype=="disp",
       posvec={Mod[N[xyzRotTran /. Thread[ToExpression[{"x", "y", "z"}] -> #2[[1]]]], 1], Det[xyz2Rot[xyzRot]]^2 N[xyzRot /. Thread[ToExpression[{"x", "y", "z"}] -> #2[[2]]]]} & @@@ BasisField,
       ftype=="spin",
       posvec={Mod[N[xyzRotTran /. Thread[ToExpression[{"x", "y", "z"}] -> #2[[1]]]], 1], Det[xyz2Rot[xyzRot]] N[xyzRot /. Thread[ToExpression[{"x", "y", "z"}] -> #2[[2]]]]} & @@@ BasisField
       ];
     difftable = DistMatrix[BasisField\[Transpose][[2]]\[Transpose][[1]], posvec\[Transpose][[1]]];
     posmap = Position[difftable, x_ /; TrueQ[Chop[x] == 0]];
     NewField = {BasisField[[#1]][[1]], posvec[[#2]], BasisField[[#1]][[3]]} & @@@ posmap,
     (*ftype=="orbital"*)
     updnbasis=Table[
       site=Mod[N[xyzRotTran /. Thread[ToExpression[{"x", "y", "z"}] -> BasisField[[i,2]][[1]]]], 1];
       updn=If[Det[xyz2Rot[xyzRot]]==1, BasisField[[i,3]], If[BasisField[[i,3]]=="up","dn","up"]];
       updn=BasisField[[i,3]];
       {site, 
        GetAngularMomentumRep[latt, First@xyzStr2TRot[grp], (Length[#]-1)/2].# &/@ BasisField[[i,2]][[2]], 
        updn}, {i,Length@BasisField}];
     upbasis=If[#[[3]]=="up",#,##&[]] &/@ updnbasis;
     dnbasis=If[#[[3]]=="dn",#,##&[]] &/@ updnbasis;
     difftable = DistMatrix[sites\[Transpose][[1]], upbasis\[Transpose][[1]]];
     posmap = Position[difftable, x_ /; TrueQ[Chop[x] == 0]];
     NewFieldup = {sites[[#1]][[2]], upbasis[[#2]][[1;;2]], upbasis[[#2]][[3]]} & @@@ posmap;
     difftable = DistMatrix[sites\[Transpose][[1]], dnbasis\[Transpose][[1]]];
     posmap = Position[difftable, x_ /; TrueQ[Chop[x] == 0]];
     NewFielddn = {sites[[#1]][[2]], dnbasis[[#2]][[1;;2]], dnbasis[[#2]][[3]]} & @@@ posmap;
     NewField = Join[NewFieldup, NewFielddn];
   ];
  Return[NewField]]
]


GetIsoTransformRules[OpMatrix_, TranType_] := Module[{IsoDim, IsoVars, VarRules, rules, i, var},

  Which[Length[Dimensions@OpMatrix]==2, 
   IsoDim = Length[OpMatrix];
   rules = If[OpMatrix != {{}},
   IsoVars = Which[TranType == "disp", 
                   Subscript[ToExpression["Iso"], #] &/@ Range[IsoDim], 
                   TranType == "spin", 
                   Subscript[ToExpression["mIso"], #] &/@ Range[IsoDim],
                   TranType == "orbital",
                   Subscript[ToExpression["eIso"], #] &/@ Range[IsoDim]];
   VarRules = IsoVars[[#1[[1]]]] -> #2 IsoVars[[#1[[2]]]] & @@@ Drop[ArrayRules[OpMatrix], -1];
   Table[First@DeleteDuplicates[Keys[VarRules[[#]]] & /@ i] -> Total[Values[VarRules[[#]]] & /@ i], {i, Table[Flatten[Position[Keys@VarRules, var]], {var, IsoVars}]}], {}];
   Return[rules],
   Length[Dimensions@OpMatrix]==3,
   GetIsoTransformRules[#, TranType] &/@ OpMatrix]
]

GetIsoStrainTransformRules[spg0_] := Module[{StrainRules},
  Which[AssociationQ[spg0],
        GetEpsilonijRule[spg0],
        ListQ[spg0],
        GetEpsilonijRule[Flatten[GTimes[spg0]]]
  ]
]

GetTransformationRules[spg0_, OpDispMatrix_, OpSpinMatrix_, OpOrbitalMatrix_] := Module[{},
  Join[#1, #2, #3, #4] & @@@ ({GetIsoTransformRules[OpDispMatrix, "disp"], 
    GetIsoTransformRules[OpSpinMatrix, "spin"], GetIsoTransformRules[OpOrbitalMatrix, "orbital"],
    GetIsoStrainTransformRules[spg0]}\[Transpose])
]

GetInvariants[seeds_, order_, OpMatrix_, spg0_, OptionsPattern[{"MustInclude"->{}}]] := Module[{fixlist, monomials, invariant, TransformRules, n, i, j, ss, factor, out, factorLCM, factorGCD, OpDispMatrix, OpSpinMatrix, OpOrbitalMatrix},
  {OpDispMatrix, OpSpinMatrix, OpOrbitalMatrix} = OpMatrix;
  out = Table[
  monomials = If[
    OptionValue["MustInclude"]=={}, 
    MonomialList[Total[seeds]^n],
    fixlist = Flatten[Table[MonomialList[Total[#1]^i], {i, #2}] &@@@ OptionValue["MustInclude"]];
    Flatten[Table[# ss & /@ MonomialList[Total[seeds]^n], {ss, fixlist}]]];
  TransformRules = GetTransformationRules[spg0, OpDispMatrix, OpSpinMatrix, OpOrbitalMatrix];
  invariant = Rationalize[DeleteDuplicates[DeleteCases[Union[Expand[Total[(monomials /. # & /@ TransformRules)]]], i_/;i==0], (#1 -#2 == 0 || #1 + #2 == 0) &]];
  SimplifyCommonFactor[invariant], {n, order}];
  Return[DeleteDuplicates[#, (#1 -#2 == 0 || #1 + #2 == 0) &] &/@ out]
]

NumberCommonDivisor[NumList_] := Module[{TempList, DenominatorLCM},
 TempList = Which[Head[#] === Integer, #, Head[#] === Times, First@Level[#, {1}], Head[#] === Power, 1, Head[#] === Rational, #] &/@ NumList;
 DenominatorLCM = If[MemberQ[TempList, _Rational], LCM @@ (Denominator[#] & /@ Extract[TempList, Position[TempList, _Rational]]), 1];
 Return[{DenominatorLCM, GCD @@ (TempList DenominatorLCM)}]
]

GetConstantFactor[expr_] := Module[{},
  If[ListQ[expr],  GetConstantFactor[#] & /@ expr, Return[(If[MatchQ[Expand@expr, Plus[_, __]], Level[Expand@expr, {1}], Level[Expand@expr, {0}]] /. Thread[Variables[Expand@expr] -> ConstantArray[1, Length[Variables[Expand@expr]]]])]]
]

SimplifyCommonFactor[expr_] := Module[{factorLCM, factorGCD},
  If[ListQ[expr], SimplifyCommonFactor[#] & /@ expr,
     {factorLCM, factorGCD} = NumberCommonDivisor[GetConstantFactor[Expand[expr]]];
     Return[Expand[factorLCM expr/factorGCD]]
   ]
]

ImposeDW[Wyckoff0_, IsoMatrix_, modeset_, {Nx_, Ny_, Nz_}] := Module[{mode, id, Amp, pos, s, ix, iy, iz, Superpos},
  Superpos = Table[{#1 + {ix, iy, iz}, #2} & @@@ Wyckoff0, {ix, 0, Nx - 1}, {iy, 0, Ny - 1}, {iz, 0, Nz - 1}];
  Do[pos = Superpos[[ix]][[iy]][[iz]];
     s = Cos[2 Pi {1/Nx, 1/Ny, 1/Nz}.{ix, iy, iz}];
     Do[id = mode[[1]]; Amp = s mode[[3]] mode[[4]];
        pos = Transpose[{#[[1]] & /@ pos + Amp If[IntegerQ[id], # & /@ Partition[IsoMatrix[[;; , id]] // Normal, 3], Print["mode not exist!"]], First@StringCases[#, RegularExpression["[[:upper:]][[:lower:]]*"]] & /@ Transpose[pos][[2]]}], {mode, modeset}
        ];
     Superpos[[ix]][[iy]][[iz]] = pos, {ix, Nx}, {iy, Ny}, {iz, Nz}
     ];
  Return[Superpos]
]

ImposeIsoStrainVariedDspMode[Wyckoff0_, IsoMatrix_, modeset_, LV_] := Module[{mode, modesetnew, id, Amp, pos, NN},
  pos = Wyckoff0;
  Do[id = mode[[1]];
     NN = 1/Norm@Flatten[LV.# & /@ Partition[Normal[IsoMatrix][[;; , id]], 3]];
     Amp = NN mode[[4]];
     pos = Transpose[{#[[1]] & /@ pos + Amp If[IntegerQ[id] , # & /@ Partition[IsoMatrix[[;; , id]] // Normal, 3], Print["mode not exist!"]],
                      First@StringCases[#, RegularExpression["[[:upper:]][[:lower:]]*"]] & /@ Transpose[pos][[2]]}],
   {mode, modeset}];
  Return[pos]
]

ShowInvariantTable[TableData_, param_, OptionsPattern["FontSize" -> 12]] := Module[{m, n},
  Print[Rotate[Grid[Table[Style[Rotate[# // Expand, -270 Degree], Black, Bold, OptionValue["FontSize"]] & /@ (Flatten[Table[{Flatten[{"param", param[[n]]}], Prepend[TableData[[n]], n]}, {n, Length@TableData}], 1][[m]]), {m, 2 Length@TableData}], Alignment -> Left, Frame -> All], 270 Degree]]]

GetIsoBasis[grp0_, pos_, ftype_, kpoint_: {{0, 0, 0}, "\[CapitalGamma]"}, ct0_: {}] := Module[{w, p, imode, latt, Wyckoff0, WyckoffSites, ZeroModeMatrix, SymmetryAdaptedBasis, Sites, IsoDispModes, IsoDispModeMatrix, OpDispMatrix, ct, ProjMat, g, basis, grpk, m, n, lp},
  grpk = GetGroupK[grp0, kpoint[[1]]];
  ct = If[Length[ct0] == 0, GetCharacters[grpk, "kpoint" -> kpoint[[2]]], ct0];
  g = Length[grpk];
  {latt, Wyckoff0} = pos;
  WyckoffSites = GetWyckoffImages[grp0, {#}] & /@ Wyckoff0;
  SymmetryAdaptedBasis = Table[
    Sites = Map[{#[[1]], #[[2]]} &, WyckoffSites[[w]]];
    IsoDispModes = MapIndexed[{First[#2], #1, 1, 0} &, Flatten[Table[Subscript[#[[2]], xyz], {xyz, 3}] & /@ Sites]];
    IsoDispModeMatrix = IdentityMatrix[3 Length[Sites]];
    OpDispMatrix = GetOpMatrix[grpk, {latt, Sites}, IsoDispModeMatrix, IsoDispModes, ftype];
    ProjMat = Table[lp = ct[[2]][[p]][[1]]; Sum[{m, n} = First@Position[ct[[1]], Keys[grpk][[i]]]; lp/g Conjugate[ct[[2]][[p, m]]] Rationalize@Normal[OpDispMatrix[[i]]], {i, g}], {p, Length[ct[[2]]]}];
    basis = Table[Complement[Orthogonalize[ProjMat[[p]].# & /@ (IsoDispModeMatrix\[Transpose])], {Table[0, {i, 3 Length[Sites]}]}], {p, Length[ct[[2]]]}];
    If[#2 == {}, Unevaluated[Sequence[]], {Table[Sites[[1]][[2]] <> " " <> #1 <> "-" <> ToString[Length@#2] <> "(" <> ToString[imode] <> ")", {imode, Length@#2}], #2}] & @@@ Thread[ct[[3]] -> basis], {w, Length@WyckoffSites}];
  IsoDispModes = MapIndexed[{First[#2], #1, 1, 0.} &, Flatten[Flatten[SymmetryAdaptedBasis, 1]\[Transpose][[1]]]];
  IsoDispModeMatrix = # & /@ Transpose[Fold[ArrayFlatten[{{#1, 0}, {0, #2}}] &, Flatten[#, 1] & /@ (#\[Transpose][[2]] & /@ SymmetryAdaptedBasis)]];
  Return[{IsoDispModes, IsoDispModeMatrix}]
]

GetSymAdaptedBasis[grp0_, pos_, kpoint_: {{0, 0, 0}, "\[CapitalGamma]"}, ftype_, ct0_: {}] := Module[{w, p, imode, WyckoffSites, ZeroModeMatrix, SymmetryAdaptedBasis, Latt, Wyckoff0, Sites, IsoDispModes, IsoDispModeMatrix, OpDispMatrix, ireps, classes, ct, ProjMat, g, basis, grpk, m, n, lp},
  grpk = GetGroupK[grp0, kpoint[[1]]];
  classes = GetClasses[grpk];
  ct = If[Length[ct0] == 0, ireps = GetSpgIreps[grp0, kpoint[[1]]]; GetSpgCT[grp0, kpoint, ireps, "print" -> False], ct0];
  g = Length[grpk];
  {Latt, Wyckoff0} = pos;
  WyckoffSites = GetWyckoffImages[grp0, {#}] & /@ Wyckoff0;
  SymmetryAdaptedBasis = Table[
    Sites = Map[{#[[1]], #[[2]]} &, WyckoffSites[[w]]];
    IsoDispModes = MapIndexed[{First[#2], #1, 1, 0} &, Flatten[Table[Subscript[#[[2]], xyz], {xyz, 3}] & /@ Sites]];
    IsoDispModeMatrix = IdentityMatrix[3 Length[Sites]];
    OpDispMatrix = GetMatrixRep[grpk, {Latt, Sites}, IsoDispModeMatrix, IsoDispModes, ftype];
    ProjMat = Table[lp = ct[[p]][[1]]; 
                    Sum[{m, n} = First@Position[classes, Keys[grpk][[i]]]; 
                    lp/g Conjugate[ct[[p, m]]] Rationalize@Normal[OpDispMatrix[[i]]], {i, g}], {p, Length[ct]}];
    basis = Table[Complement[Orthogonalize[ProjMat[[p]].# & /@ IsoDispModeMatrix], {Table[0, {i, 3 Length[Sites]}]}], {p, Length[ct]}];
    If[#2 == {}, ## &[], {Table[Sites[[1]][[2]] <> " " <> kpoint[[2]] <> ToString[#1] <> "-" <> ToString[Length@#2] <> "(" <> ToString[imode] <> ")", {imode, Length@#2}], #2}] & @@@ Thread[Range[Length[ct]] -> basis], {w, Length@WyckoffSites}];
  IsoDispModes = MapIndexed[{First[#2], #1, 1, 0.} &, Flatten[Flatten[SymmetryAdaptedBasis, 1]\[Transpose][[1]]]];
  IsoDispModeMatrix = # & /@ Transpose[Fold[ArrayFlatten[{{#1, 0}, {0, #2}}] &, Flatten[#, 1] & /@ (#\[Transpose][[2]] & /@ SymmetryAdaptedBasis)]];
  Return[{IsoDispModes, IsoDispModeMatrix}]
]

FieldCode2var[code_, varstr_, OptionsPattern[{"rec"->False}]] := Module[{x1, x2, x3},
  {x1, x2, x3} = If[OptionValue["rec"], Mod[code[[1]], 1], code[[1]]];
  If[ListQ[code[[2]]], 
     Sign[code[[2]].{1, 2, 3}] Subscript[ToExpression[varstr], Abs[code[[2]].{1, 2, 3}], x1, x2, x3],
     Which[MatchQ[code[[2]], _Subscript], Construct@@Join[{Head[code[[2]]]}, Level[code[[2]], {1}], code[[1]]], 
           MatchQ[code[[2]], _Times], Level[code[[2]], {1}][[1]] Construct@@Join[{Subscript}, Level[code[[2]], {2}], code[[1]]],
           True, Print["expression not in the right form!"]
       ]
     ]
]

GetSiteCluster[spg0_, PosVec_, ftype_?StringQ, OptionsPattern[{"IsoTranRules"->{}}]] := Block[{xyzStrData, xyzRotTranData, xyzTranslation, xyzRotData, field, newpos, newvec, difftable, diff, posmap, i, j, det},
  det = If[ftype=="spin",1,2];
  xyzStrData = Which[AssociationQ[spg0], Keys[spg0], ListQ[spg0], spg0];
  xyzRotTranData = Table[ToExpression["{" <> xyzStrData[[i]] <> "}"], {i, Length[xyzStrData]}];
  xyzTranslation = xyzRotTranData /. {ToExpression["x"] -> 0, ToExpression["y"] -> 0, ToExpression["z"] -> 0};
  xyzRotData = xyzRotTranData - xyzTranslation;

  If[OptionValue["IsoTranRules"]=={},
    newvec = If[ftype=="spin"||ftype=="disp",
                Table[Det[xyz2Rot[op]]^det op /. Thread[ToExpression[{"x", "y", "z"}] -> #] & /@ (PosVec\[Transpose][[2]]), {op, xyzRotData}],
                Print["Only l=1 type vector field can be transformed without given IsoTranRules"];
                Abort[];
      ];
    newpos = Table[op /. Thread[ToExpression[{"x", "y", "z"}] -> #] & /@ (PosVec\[Transpose][[1]]), {op, xyzRotData}];,
    newvec = Table[PosVec\[Transpose][[2]] /. op, {op, OptionValue["IsoTranRules"]}];
    newpos = Table[op /. Thread[ToExpression[{"x", "y", "z"}] -> #] & /@ (PosVec\[Transpose][[1]]), {op, xyzRotData}];
  ];
 
  Return[Rationalize[{#[[1]], #[[2]]}]\[Transpose] &/@ ({newpos, newvec}\[Transpose])]
]

GetSiteInt[spg0_, field_, OptionsPattern[{"IsoTranRules"->{}}]] := Module[{tij, factor, OpMatrix},
  tij = Total@Fold[Times, Table[FieldCode2var[#, posvec[[1]]] & /@ Flatten[GetSiteCluster[spg0, {posvec[[2]]}, posvec[[3]], "IsoTranRules"->OptionValue["IsoTranRules"]], 1], {posvec, field}]];
  factor = GCD @@ (If[MatchQ[tij, Plus[_, __]], Level[tij, {1}], Level[tij, {0}]] /. Thread[Variables[tij] -> ConstantArray[1, Length[Variables[tij]]]]);
  Return[If[factor == 0, 0, Expand[tij/factor]]]
] 

InvariantEOnSite[expr_] := Module[{X, i, dx, dy, dz},
  expr /. {Subscript[X_, i_, dx_, dy_, dz_] :> Subscript[X, i, ToExpression["ix"] + dx, ToExpression["iy"] + dy, ToExpression["iz"] + dz]}
]
(*-------------------------- Attributes ------------------------------*)

(*Attributes[]={Protected, ReadProtected}*)

End[]

EndPackage[]
