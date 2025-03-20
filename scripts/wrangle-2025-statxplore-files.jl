using XLSX,DataFrames
nrows,ncols = size(d1)    
d1 = XLSX.readtable( "julia/vw/ScottishTaxBenefitModel/data/2025-6/table_2025-03-19_13-45-40.xlsx", 1, "B:AB"; first_row=11)|>DataFrame
delete!(d1,1)
nrows,ncols = size(d1)    
for i in 2:12
   d2 = XLSX.readtable( "julia/vw/ScottishTaxBenefitModel/data/2025-6/table_2025-03-19_13-45-40.xlsx", i, "B:AB"; first_row=11)|>DataFrame
   delete!(d2,1)
   @assert size(d1) == size(d2)
   for r in 1:nrows, c in 1:ncols
      if (typeof( d2[r,c] )<:Number) && (typeof(d1[r,c])<:Number)
         d1[r,c] += d2[r,c]
      end
   end
end

permutedims(d1,1)
d1