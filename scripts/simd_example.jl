using SIMD

# Define vector size - should be a multiple of SIMD vector width
const M = 1024
const N = M*16
const T = Float64

# Create some test vectors
a = rand(T, N)
b = rand(T, N)
c = zeros(T, N)

# Regular Julia vectorized operation (baseline)
function vector_add_regular!(c, a, b)
    @inbounds for i in eachindex(a)
        c[i] = a[i] + b[i]
    end
end

# SIMD-optimized version
function vector_add_simd!(c, a, b)
    # SIMD vector type for T
    VT = Vec{8,T}  # 8 T values per SIMD vector

    # Process in chunks that fit SIMD vectors
    @inbounds for i in 1:8:length(a)-7
        # Load SIMD vectors
        va = vload(VT, a, i)
        vb = vload(VT, b, i)

        # Perform SIMD addition
        vc = va + vb

        # Store result
        vstore(vc, c, i)
    end

    # Handle remaining elements (if N is not divisible by 8)
    remainder = length(a) % 8
    if remainder > 0
        start_idx = length(a) - remainder + 1
        for i in start_idx:length(a)
            c[i] = a[i] + b[i]
        end
    end
end

# More complex example: multiple operations per load
function complex_computation_simd!(result, a, b, c, d)
    VT = Vec{8,T}

    @inbounds for i in 1:8:length(a)-7
        va = vload(VT, a, i)
        vb = vload(VT, b, i)
        vc = vload(VT, c, i)
        vd = vload(VT, d, i)

        # Multiple operations: result = (a * b + c) / d + sin(a)
        temp1 = muladd(va, vb, vc)
        temp2 = temp1 / vd
        vr = temp2 + sin(va)  # Expensive operation

        vstore(vr, result, i)
    end

    # Handle remainder
    remainder = length(a) % 8
    if remainder > 0
        start_idx = length(a) - remainder + 1
        for i in start_idx:length(a)
            result[i] = (a[i] * b[i] + c[i]) / d[i] + sin(a[i])
        end
    end
end

# Regular version for comparison
function complex_computation_regular!(result, a, b, c, d)
    @inbounds for i in 1:length(a)
        result[i] = (a[i] * b[i] + c[i]) / d[i] + sin(a[i])
    end
end

# Example where SIMD helps: horizontal operations
function sum_of_squares_simd(a)
    VT = Vec{8,T}
    sum_vec = zero(VT)

    @inbounds for i in 1:8:length(a)-7
        va = vload(VT, a, i)
        sum_vec += va * va
    end

    # Horizontal sum of SIMD vector
    total = sum(sum_vec)

    # Handle remainder
    remainder = length(a) % 8
    if remainder > 0
        start_idx = length(a) - remainder + 1
        for i in start_idx:length(a)
            total += a[i] * a[i]
        end
    end

    return total
end

# Benchmark the functions
using BenchmarkTools

println("Benchmarking vector addition:")
println("Regular:")
@btime vector_add_regular!($c, $a, $b)

println("SIMD:")
@btime vector_add_simd!($c, $a, $b)

# Test more complex operations where SIMD helps
d = rand(T, N) .+ 0.1f0  # Avoid division by zero
result = zeros(T, N)

println("\nComplex computation:")
println("Regular:")
@btime complex_computation_regular!($result, $a, $b, $c, $d)

println("SIMD:")
@btime complex_computation_simd!($result, $a, $b, $c, $d)

println("\nSum of squares:")
println("Regular sum:")
@btime sum($a .* $a)

println("SIMD sum:")
@btime sum_of_squares_simd($a)

# Verify correctness
c_regular = zeros(T, N)
c_simd = zeros(T, N)

vector_add_regular!(c_regular, a, b)
vector_add_simd!(c_simd, a, b)

println("\nResults match: ", isapprox(c_regular, c_simd))