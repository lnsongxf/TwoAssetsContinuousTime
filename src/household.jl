mutable struct Household

    V       ::Union{SharedArray{Float64}, Array{Float64}}
    Vupdt   ::Array{Float64}
    Vupdtvec::Array{Float64}
    c       ::Union{SharedArray{Float64}, Array{Float64}}
    d       ::Union{SharedArray{Float64}, Array{Float64}}
    adot    ::Union{SharedArray{Float64}, Array{Float64}}
    bdot    ::Union{SharedArray{Float64}, Array{Float64}}

    VaB     ::Union{SharedArray{Float64}, Array{Float64}}
    VaF     ::Union{SharedArray{Float64}, Array{Float64}}
    VbB     ::Union{SharedArray{Float64}, Array{Float64}}
    VbF     ::Union{SharedArray{Float64}, Array{Float64}}
    cB      ::Union{SharedArray{Float64}, Array{Float64}}
    cF      ::Union{SharedArray{Float64}, Array{Float64}}
    dBB     ::Union{SharedArray{Float64}, Array{Float64}}
    dBF     ::Union{SharedArray{Float64}, Array{Float64}}
    dFB     ::Union{SharedArray{Float64}, Array{Float64}}
    dFF     ::Union{SharedArray{Float64}, Array{Float64}}
    dB      ::Union{SharedArray{Float64}, Array{Float64}}
    dF      ::Union{SharedArray{Float64}, Array{Float64}}
    scB     ::Union{SharedArray{Float64}, Array{Float64}}
    scF     ::Union{SharedArray{Float64}, Array{Float64}}
    sdB     ::Union{SharedArray{Float64}, Array{Float64}}
    sdF     ::Union{SharedArray{Float64}, Array{Float64}}

    X       ::Union{SharedArray{Float64}, Array{Float64}}
    Y       ::Union{SharedArray{Float64}, Array{Float64}}
    Z       ::Union{SharedArray{Float64}, Array{Float64}}
    Λ       ::SparseMatrixCSC{Float64, Int64}
    B       ::SparseMatrixCSC{Float64, Int64}
    D       ::SparseMatrixCSC{Float64, Int64}
    A       ::SparseMatrixCSC{Float64, Int64}

    function Household(p::Param)
        # state space:
        # first dimension is liquid asset
        # second dimension is illiquid asset
        # third dimension is productivity
        this = new()

        # m           = SharedArray{Float64,3}((p.nI, p.nJ, p.nK))
        m           = zeros(p.nI, p.nJ, p.nK)
        ms          = spzeros(p.nI * p.nJ * p.nK, p.nI * p.nJ * p.nK)
        for e in fieldnames(Household)
            if !∈(e, [:Λ; :B; :D; :A; :Vupdtvec])
                setfield!(this, e, copy(m))
            elseif e == :Vupdtvec
                this.Vupdtvec = zeros(p.nI * p.nJ * p.nK)
            else
                setfield!(this, e, copy(ms))
            end
        end
        # TODO: so far valid only for 2 state income process
        this.Λ[:] = sparse([Diagonal(-p.λ[1,2] * ones(p.nI * p.nJ)) Diagonal(p.λ[1,2] * ones(p.nI * p.nJ));
                     Diagonal(p.λ[2,1] * ones(p.nI * p.nJ)) Diagonal(-p.λ[2,1] * ones(p.nI * p.nJ))])

        for (k,z) in enumerate(p.gZ)
            this.V[:,:,k] = u(p, (1 - p.ξ) * z * p.w .+ (p.ra * p.gA)' .+ (p.rb + p.κ).* p.gB) ./ p.ρ
        end

        return this
    end
end

u(p, c)     = c.^(1 - p.σ) ./ (1 - p.σ)
∂u(p, c)    = c.^(-p.σ)
inv_∂u(p, x) = (x).^(-1 / p.σ)