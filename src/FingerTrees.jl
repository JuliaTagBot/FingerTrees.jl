module FingerTrees
using Nullables
import Base: reduce, length, collect, split, eltype, isempty

export FingerTree, conjl, conjr, splitl, splitr, len, fingertree, flat, split, travstruct, traverse, concat, <|, |>, assoc
export EmptyFT

<|(a, b) = conjl(a,b)
|>(a, b) = conjr(a,b)
..(a,b) = concat(a,b)

abstract type FingerTree{T}  # T is the element type, can also represent a higher order tree of actual type FingerTree{Tree23{T}}
end
abstract type Tree23{T}
end

struct Leaf23{T} <: Tree23{T}
    a::T
    b::T
    c::Nullable{T}
    len::Int
    depth::Int
    function Leaf23(a::T, b::T) where {T}
        if !(dep(a)==dep(b)) error("Try to construct uneven Leaf2") end
        new{T}(a, b, Nullable{T}(), len(a)+len(b), dep(a)+1)
    end
    function Leaf23(a::T, b::T, c::T) where {T}
        if !(dep(a)==dep(b)==dep(c)) error("Try to construct uneven Leaf3") end
        new{T}(a,b,c, len(a)+len(b)+len(c), dep(a)+1)
    end
end

struct Node23{T} <: Tree23{T}
    a::Tree23{T}
    b::Tree23{T}
    c::Nullable{Tree23{T}}
    len::Int
    depth::Int
    function Node23(a::Tree23{T}, b::Tree23{T}) where {T}
        if !(dep(a)==dep(b)) error("Try to construct uneven Node2") end
        new{T}(a, b, Nullable{Tree23}(), len(a)+len(b), dep(a)+1)
    end
    function Node23(a::Tree23{T}, b::Tree23{T}, c::Tree23{T}) where {T}
        if !(dep(a)==dep(b)==dep(c)) error("Try to construct uneven Node3") end
        new{T}(a,b,c, len(a)+len(b)+len(c), dep(a)+1)
    end
end

Tree23(a,b,c) = Leaf23(a,b,c)
Tree23(a,b) = Leaf23(a,b)
Tree23(a::Tree23{T},b::Tree23{T},c::Tree23{T}) where {T} = Node23(a,b,c)
Tree23(a::Tree23{T},b::Tree23{T}) where {T} = Node23(a,b)

abstract type DigitFT{T,N}

end

struct DLeaf{T,N} <: DigitFT{T,N} # N in 1:4 by constructor restriction
    child::NTuple{N, T}
    len::Int
    depth::Int
    DLeaf(a::T) where {T} = new{T,1}((a,), len(a), 0)
    function DLeaf(a::T,b::T) where {T}
        new{T,2}((a,b), len(a)+len(b), 0)
    end
    function DLeaf(a::T,b::T,c::T) where {T}
        new{T,3}((a,b,c), len(a)+len(b)+len(c), 0)
    end
    function DLeaf(a::T,b::T,c::T,d::T) where {T}
        new{T,4}((a,b,c,d), +(len(a),len(b),len(c),len(d)), 0)
    end
end


struct DNode{T,N} <: DigitFT{T,N}
    child::NTuple{N, Tree23{T}}
    len::Int
    depth::Int
    DNode(a::Tree23{T}) where {T} = new{T,1}((a,), len(a), dep(a))
    function DNode(a::Tree23{T},b::Tree23{T}) where {T}
        if dep(a)!=dep(b) error("Try to construct uneven digit $b") end
        new{T,2}((a,b), len(a)+len(b), dep(a))
    end
    function DNode(a::Tree23{T},b::Tree23{T},c::Tree23{T}) where {T}
        if !(dep(a)==dep(b)==dep(c)) error("Try to construct uneven digit $b ") end
        new{T,3}((a,b,c), len(a)+len(b)+len(c), dep(a))
    end
    function DNode(a::Tree23{T},b::Tree23{T},c::Tree23{T},d::Tree23{T}) where {T}
        if !(dep(a)==dep(b)==dep(c)==dep(d)) error("Try to construct uneven digit $b") end
        new{T,4}((a,b,c,d), +(len(a),len(b),len(c),len(d)), dep(a))
    end
end

DigitFT1{T} = DigitFT{T,1}
DigitFT2{T} = DigitFT{T,2}
DigitFT3{T} = DigitFT{T,3}
DigitFT4{T} = DigitFT{T,4}

DigitFT(a) = DLeaf(a)
DigitFT(a,b) = DLeaf(a,b)
DigitFT(a,b,c) = DLeaf(a,b,c)
DigitFT(a,b,c,d)  = DLeaf(a,b,c,d)
DigitFT(a::Tree23{T}) where {T} = DNode(a)
DigitFT(a::Tree23{T},b::Tree23{T}) where {T} = DNode(a,b)
DigitFT(a::Tree23{T},b::Tree23{T},c::Tree23{T}) where {T} = DNode(a,b,c)
DigitFT(a::Tree23{T},b::Tree23{T},c::Tree23{T},d::Tree23{T}) where {T} = DNode(a,b,c,d)

function digit(n::Tree23{T}) where T
    if isnull(n.c)
        DigitFT(n.a, n.b)
    else
        DigitFT(n.a, n.b, get(n.c))
    end
end
digit(t::NTuple{N,T}) where {N, T} = DigitFT(t...)
digit(t::T) where {T} = DigitFT(t)

struct EmptyFT{T} <: FingerTree{T}
end

struct SingleFT{T} <: FingerTree{T}
    a::Union{T, Tree23{T}}
    SingleFT(a::T) where {T} = new{T}(a)
    SingleFT(a::Tree23{T}) where {T} = new{T}(a)
end


struct DeepFT{T} <: FingerTree{T}
    left::DigitFT{T}
    succ::FingerTree{T} # is infact a FingerTree{Node{T}}
    right::DigitFT{T}
    len::Int
    depth::Int
    function DeepFT(l::DigitFT{T,N}, s::FingerTree{T}, r::DigitFT{T,M}) where {T,N,M}
        if !(dep(l) == dep(s) - 1 == dep(r) || (isempty(s) && dep(l) == dep(r)))
            dump(l); dump(s);dump(r)
            error("Attempt to construct uneven finger tree")
        end
        new{T}(l, s, r, len(l) + len(s) + len(r), dep(l))
    end
#=    function DeepFT(ll, s::FingerTree{T}, rr) where {T}
        l = DigitFT(ll)
        r = DigitFT(rr)

        if !(dep(l) == dep(s) - 1 == dep(r) || (isempty(s) && dep(l) == dep(r)))
            dump(l); dump(s);dump(r)
            error("Attempt to construct uneven finger tree")
        end
        new{T}(l, s, r, len(l) + len(s) + len(r), dep(l))
    end=#
end
#=
DeepFT(l::DigitFT{T}, s::FingerTree{T} , r::DigitFT{T}) where {T} = DeepFT{T}(l, s, r)
=#
DeepFT(l::T, s::FingerTree{T}, r::T) where {T} = DeepFT(digit(l), s, digit(r))
#DeepFT(l::Leaf23{T}, s::FingerTree{T}, r::Leaf23{T}) where {T} = DeepFT(l, s, r)
DeepFT(l::Tree23{T}, s::FingerTree{T}, r::Tree23{T}) where {T} = DeepFT(DigitFT(l), s, DigitFT(r))
#DeepFT(l::DigitFT, s::FingerTree{T}, r::DigitFT) where {T} = DeepFT(DigitFT(l), s, DigitFT(r))

DeepFT(l::T, r::T) where {T} = DeepFT(DigitFT(l), EmptyFT{T}(), DigitFT(r))
DeepFT(l::Tree23{T}, r::Tree23{T}) where {T} = DeepFT(DigitFT(l), EmptyFT{T}(), DigitFT(r))
DeepFT(l::DigitFT{T}, r::DigitFT{T}) where {T} = DeepFT(l, EmptyFT{T}(), r)


# to safe (a lot of) compilation time, the depth of the tree is tracked and not guaranteed by a type constraint

dep(_) = 0
dep(n::Tree23) = n.depth
dep(d::DigitFT) = d.depth
dep(s::SingleFT) = dep(s.a)
dep(_::EmptyFT) = 0
dep(ft::DeepFT) = ft.depth

eltype(b::FingerTree{T}) where {T} = T
eltype(b::DigitFT{T}) where {T} = T


# decoration with a predicate
# TODO: allow other counting functions then len=length

len(a) = 1
len(n::NTuple{N, Leaf23}) where {N} = mapreduce(len, +, n)::Int
len(_::Tuple{}) = 0
len(n::NTuple{N, Node23}) where {N} = mapreduce(len, +, n)::Int

len(n::Tree23) = n.len
len(digit::DigitFT) = digit.len
len(_::EmptyFT) = 0

len(deep::DeepFT) = deep.len
len(n::SingleFT) = len(n.a)
length(ft::FingerTree) = len(ft)

isempty(_::EmptyFT) = true
isempty(_::FingerTree) = false

width(digit::DigitFT{T,N}) where {T,N} = N::Int
width(n::Tree23) = length(isnull(n.c) ? 3 : 2)

# constructor

FingerTree(::Type{K},ft::FingerTree{K}) where {K} = ft
FingerTree(::Type{K}, n::Tree23{K}) where {K} = fingertree(n)
function FingerTree(K,t)
    ft = EmptyFT{K}()
    for x in t
        ft = conjr(ft, x)
    end
    ft
end
FingerTree(a) = FingerTree(eltype(a), a)

# short conversions

fingertree(_::Tuple{}) = error("Attempt to create untyped empty FingerTree")
fingertree(a) = SingleFT(a)
fingertree(a,b) = DeepFT(a, b)
fingertree(a,b,c) = DeepFT(DigitFT(a,b), DigitFT(c))
fingertree(a,b,c,d) = DeepFT(DigitFT(a,b), DigitFT(c,d))
fingertree(a,b,c,d,e) = DeepFT(DigitFT(a,b,c), DigitFT(d,e))
fingertree(a,b,c,d,e,f) = DeepFT(DigitFT(a,b,c), DigitFT(d,e,f))
fingertree(a,b,c,d,e,f,g) = DeepFT(DigitFT(a,b,c,d), DigitFT(e,f,g))
fingertree(a,b,c,d,e,f,g,h) = DeepFT(DigitFT(a,b,c,d), DigitFT(e,f,g,h))

toftree(d::FingerTree) = d
toftree(d::DigitFT{T}) where {T} = fingertree(d.child...)
toftree(d::Tree23{T}) where {T} = fingertree(astuple(d)...)
toftree(d::NTuple{1, T}) where {T} = fingertree(d[1])
toftree(d::NTuple{2, T}) where {T} = fingertree(d[1],d[2])
toftree(d::NTuple{3, T}) where {T} = fingertree(d...)
toftree(d::NTuple{4, T}) where {T} = fingertree(d...)

astuple(n::Tree23) = isnull(n.c) ? (n.a, n.b) : (n.a, n.b, get(n.c))
astuple(d::DigitFT) = d.child




conjl(a, digit::DigitFT1{T}) where {T} = DigitFT(a, digit.child[1])
conjl(a, digit::DigitFT2{T}) where {T} = DigitFT(a, digit.child[1], digit.child[2])
conjl(a, digit::DigitFT3{T}) where {T} = DigitFT(a, digit.child...)

conjr(digit::DigitFT1{T}, a) where {T} = DigitFT(digit.child[1], a)
conjr(digit::DigitFT2{T}, a) where {T} = DigitFT(digit.child[1], digit.child[2], a)
conjr(digit::DigitFT3{T}, a) where {T} = DigitFT(digit.child..., a)


splitl(digit::DigitFT2{T}) where {T} = digit.child[1], DigitFT(digit.child[2])
splitl(digit::DigitFT3{T}) where {T} = digit.child[1], DigitFT(digit.child[2:end]...)
splitl(digit::DigitFT4{T}) where {T} = digit.child[1], DigitFT(digit.child[2:end]...)

splitr(digit::DigitFT2{T}) where {T} = DigitFT(digit.child[1]), digit.child[end]
splitr(digit::DigitFT3{T}) where {T} = DigitFT(digit.child[1:end-1]...), digit.child[end]
splitr(digit::DigitFT4{T}) where {T} = DigitFT(digit.child[1:end-1]...), digit.child[end]

function Base.getindex(d::DigitFT, i::Int)
    for k in 1:width(d)
        j = len(d.child[k])
        if i <= j return getindex(d.child[k], i) end
        i -= j
    end
    throw(BoundsError())
end
function Base.getindex(n::Tree23, i::Int)
    j = len(n.a)
    i <= j && return getindex(n.a, i)
    i -= j; j = len(n.b)
    i <= j && return getindex(n.b, i)
    if !isnull(n.c)
        i -= j; j = len(get(n.c))
        i <= j && return getindex(get(n.c), i)
    end
    throw(BoundsError())
end

Base.getindex(::EmptyFT, i) = throw(BoundsError())
Base.getindex(ft::SingleFT, i) = getindex(ft.a, i)
function Base.getindex(ft::DeepFT, i)
    j = len(ft.left)
    if i <= j return getindex(ft.left, i) end
    i -= j; j = len(ft.succ)
    if i <= j return getindex(ft.succ, i) end
    i -= j; j = len(ft.right)
    if i <= j return getindex(ft.right, i) end
    throw(BoundsError())
end

conjl(a::T, _::EmptyFT{T}) where {T} = SingleFT(a)
conjr(_::EmptyFT{T}, a::T) where {T} = SingleFT(a)

conjl(a::Tree23{T}, _::EmptyFT{T}) where {T} = SingleFT(a)
conjr(_::EmptyFT{T}, a::Tree23{T}) where {T} = SingleFT(a)

conjl(a, single::SingleFT{K}) where {K} = DeepFT(a,EmptyFT{K}(), single.a)
conjr(single::SingleFT{K}, a) where {K} = DeepFT(single.a, EmptyFT{K}(),a)




function splitl(_::EmptyFT)
    error("finger tree empty")
end
splitr(l::EmptyFT) = splitl(l)

function splitl(single::SingleFT{K}) where K
    single.a, EmptyFT{K}()
end
function splitr(single::SingleFT{K}) where K
     EmptyFT{K}(), single.a
end
function conjl(a, ft::DeepFT{T}) where T
    if width(ft.left) < 4
        DeepFT(conjl(a,ft.left), ft.succ, ft.right)
    else
        f = Tree23(ft.left.child[2], ft.left.child[3], ft.left.child[4])
        DeepFT(DigitFT(a, ft.left.child[1]), conjl(f,ft.succ), ft.right)
    end
end

function conjr(ft::DeepFT, a)
    if width(ft.right) < 4
        DeepFT(ft.left, ft.succ, conjr(ft.right, a))
    else
        f = Tree23(ft.right.child[1:3]...)
        DeepFT(ft.left, conjr(ft.succ, f), DigitFT(ft.right.child[4], a))
    end
end

function splitl(ft::DeepFT) # like lview. note that return . (,) x $ y equals return (x, y) in haskell
    if width(ft.left) > 1
        a, as = splitl(ft.left)
        return a, DeepFT(as, ft.succ, ft.right)
    else
        a = ft.left.child[1]
        if isempty(ft.succ)
            return a, toftree(ft.right)
        else
            c, gt = splitl(ft.succ)
            return a, DeepFT(digit(c), gt, ft.right)
        end
    end
end
function splitr(ft::DeepFT)
    if width(ft.right) >1
        as, a = splitr(ft.right)
        return DeepFT(ft.left, ft.succ, as), a
    else
        a = ft.right.child[1]
        if isempty(ft.succ)
            return toftree(ft.left), a
        else
            gt, c = splitr(ft.succ)
            return DeepFT(ft.left, gt, digit(c)), a
        end
    end
end

function splitv(t, i)
    t[1:i-1], t[i], t[i+1:end]
end

function split(d::DigitFT, i)
    for k in 1:width(d)
        j = len(d.child[k])
        if i <= j
            return splitv(d.child, k) end
        i -= j
    end
    throw(BoundsError())
end
function split(n::Leaf23, i)
    if isnull(n.c)
        j = len(n.a)
        i <= j  && return (), n.a, (n.b,)
        i -= j; j = len(n.b)
        i <= j  && return (n.a,), n.b, ()
    else
        j = len(n.a)
        i <= j  && return (), n.a, (n.b,get(n.c))
        i -= j; j = len(n.b)
        i <= j  && return (n.a,), n.b, (get(n.c),)
        i -= j; j = len(get(n.c))
        i <= j  && return (n.a,n.b), get(n.c), ()
    end
    throw(BoundsError())
end

function split(n::Node23, i)
    if isnull(n.c)
        j = len(n.a)
        i <= j  && return (), n.a, (n.b,)
        i -= j; j = len(n.b)
        i <= j  && return (n.a,), n.b, ()
    else
        j = len(n.a)
        i <= j  && return (), n.a, (n.b,get(n.c))
        i -= j; j = len(n.b)
        i <= j  && return (n.a,), n.b, (get(n.c),)
        i -= j; j = len(get(n.c))
        i <= j  && return (n.a,n.b), get(n.c), ()
    end
    throw(BoundsError())
end


function collect(xs::FingerTree)
     v = Array(eltype(xs), len(xs))
     traverse((x, i) -> (v[i] = x;), xs)
     v
end

NonEmptyFT{T} = Union{SingleFT{T},DeepFT{T}}
deepl(t::Tuple{}, ft::EmptyFT{T}, dr::DigitFT) where {T} = toftree(dr)
deepl(t::Tuple{}, ft::NonEmptyFT{T}, dr::DigitFT) where {T} = begin
    if isempty(ft)
        return toftree(dr)
    end
    x, ft2 = splitl(ft)
    x = digit(x)
#    isa(ft2, SingleFT{T}) && isa(ft2.a, T) && return fingertree(x.child..., ft2.a, dr.child...)
    DeepFT(x, ft2, dr)
end
deepl(d::DigitFT, ft::DeepFT{T}, dr::DigitFT) where {T} = DeepFT(d, ft, dr)
deepl(t, ft::NonEmptyFT{T}, dr::DigitFT) where {T} = DeepFT(DigitFT(t...), ft, dr)
deepl(t, ft::EmptyFT{T}, dr::DigitFT) where {T} = DeepFT(digit(t), ft, dr)

deepr(d::DigitFT, ft::EmptyFT{T}, t::Tuple{}) where {T} = toftree(d)
deepr(d::DigitFT, ft::NonEmptyFT{T}, t::Tuple{}) where {T} = begin
    if isempty(ft)
        return toftree(d)
    end
    ft2, x = splitr(ft)
    x = digit(x)
#    isa(ft2, SingleFT{T}) && isa(ft2.a, T) && return fingertree(d.child..., ft2.a, x.child...)
    DeepFT(d, ft2, x)
end
deepr(d::DigitFT, ft::DeepFT{T}, dr::DigitFT) where {T} = DeepFT(d, ft, dr)
deepr(d::DigitFT, ft::NonEmptyFT{T}, t) where {T} = DeepFT(d, ft, DigitFT(t...))
deepr(d::DigitFT, ft::EmptyFT{T}, t) where {T} = DeepFT(d, ft, DigitFT(t...))

function split(ft::EmptyFT, i)
    error("can't split empty FingerTree")
end

function split(ft::SingleFT{K}, i) where K
#    if isa(ft.a, Tree23) return split(ft.a, i) end
    e = EmptyFT{K}()
    return e, ft.a, e
end


function split(ft::DeepFT{T}, i) where T
    j = len(ft.left)
    if i <= j
        l, x, r = split(ft.left, i) #splitdigit
        return isempty(l) ? EmptyFT{T}() : toftree(l), x, deepl(r, ft.succ, ft.right)
    end
    i -= j; j = len(ft.succ)
    if i <= j
        ml, xs, mr = split(ft.succ, i) #splittree
        i -= len(ml)
        l, x, r = isa(xs, T) ? ((),xs,()) : split(xs, i) #splitnode
        ml = isempty(ml) ? EmptyFT{T}() : toftree(ml)
        mr = isempty(mr) ? EmptyFT{T}() : toftree(mr)
        return deepr(ft.left, ml, l), x, deepl(r, mr, ft.right)
    end
    i -= j; j = len(ft.right)
    if i <= j
        l, x, r = split(ft.right, i)
        return deepr(ft.left, ft.succ, l), x, isempty(r) ? EmptyFT{T}() : toftree(r)
    end
    throw(BoundsError())
end

function assoc(ft::FingerTree{T},a::T, i) where T
    l, _, r  = split(ft, i)
    (l |> a) .. r
end

function Base.getindex(ft::DeepFT, r::UnitRange)
    i = start(r)
    j = last(r)
    _, _, y  = split(ft, i-1)
    y, _, _  = split(y, j-i+1)
    y
end



Base.reduce(op::Function, v, ::EmptyFT) = v
Base.reduce(op::Function, v, t::SingleFT) = reduce(op, v, ft.a)
function Base.reduce(op::Function, v, d::DigitFT)
    for k in 1:width(d)
        v = reduce(op, v, d.child[k])
    end
    v
end
function Base.reduce(op::Function, v, n::Tree23)
    t = tuple(n)
    for k in 1:width(t)
        v = reduce(op, v, t[k])
    end
    v
end
function Base.reduce(op::Function, v, ft::DeepFT)
    v = reduce(op, v, ft.left)
    v = reduce(op, v, ft.succ)
    v = reduce(op, v, ft.right)
end

traverse(op::Function, a, i) = (op(a, i); i + 1)
traverse(op::Function,  ::EmptyFT, i) = return i
traverse(op::Function, ft::SingleFT, i) = traverse(op, ft.a, i)

function traverse(op::Function, n::DigitFT, i)
    for k in 1:width(n)
        i = traverse(op, n.child[k], i)
    end
    i
end
function traverse(op::Function, n::Tree23, i)
    i = traverse(op, n.a, i)
    i = traverse(op, n.b, i)
    !isnull(n.c) && (i = traverse(op, get(n.c), i))
    i
end
function traverse(op::Function, ft::DeepFT, i)
    i = traverse(op, ft.left, i)
    i = traverse(op, ft.succ, i)
    traverse(op, ft.right, i)
end
traverse(op, ft) = (traverse(op, ft, 1);)


#Traversal with a op that takes also the depth as input
travstruct(op::Function, a, d) = (op(a, d);d)
travstruct(op::Function,  ::EmptyFT, d) = return d
travstruct(op::Function, ft::SingleFT, d) = travstruct(op, ft.a, d)
function travstruct(op::Function,n::DigitFT{T}, d) where T
    d2 = travstruct(op, n.child[1], d)
    for k in 2:width(n)
        @assert(d2 == travstruct(op, n.child[k], d ))
    end
    d2
end
function travstruct(op::Function, ft::DeepFT, d)
    d2 = travstruct(op, ft.left, d)
    @assert(d2 == travstruct(op, ft.succ, d + 1) - 1 ==  travstruct(op, ft.right, d))
    d2
end
travstruct(op, ft) = travstruct(op, ft, 1)

#=
# Scheme:
# state = start(I)
# while !done(I, state)
#   (i, state) = next(I, state)
#     # body
# end
# rather slow
function start(ft::FingerTree)
    trav = () -> traverse((x,i) -> produce(x), ft)
    t = Task(trav)
    i = consume(t)
    (i, t)
end
function next(ft::FingerTree, state)
    state[1], (consume(state[2]), state[2])
end
function done(ft::FingerTree, state)
    state[2].state==:done
end
=#

function conjlall(t)
    ft = t[end]
    for i in length(t)-1:-1:1
        ft = conjl(t[i], ft)
    end
    ft
end
function conjrall(t)
    ft = t[1]
    for x in t[2:end]
        ft = conjr(ft, x)
    end
    ft
end



app3(l::SingleFT, ts, r::SingleFT) = fingertree(l.a, ts..., r.a)
app3(::EmptyFT, ts, r::EmptyFT) = fingertree(ts...) # for example ts::NTuple{N,Tree23}
app3(::EmptyFT, ts, r::SingleFT) = fingertree(ts..., r.a)
app3(l::SingleFT, ts, ::EmptyFT) = fingertree(l.a, ts...)
app3(::EmptyFT, ts, r) = conjlall(tuple(ts..., r)) # conjall can be avoided... TODO
app3(l, ts, ::EmptyFT) = conjr(l, ts...)
app3(x::SingleFT, ts, r) = conjl(x.a, conjlall(tuple(ts..., r)))
app3(l, ts, x::SingleFT) = conjr(conjrall(tuple(l, ts...)), x.a)


nodes(a,b) = (Tree23(a, b),)
nodes(a,b,c) = (Tree23(a,b,c),)
nodes(a,b,c,d) = (Tree23(a, b), Tree23(c,d))
nodes(a,b,c,xs...) = tuple(Tree23(a,b,c), nodes(xs...)...)

app3(l::DeepFT, ts, r::DeepFT) =
    DeepFT(l.left, app3(l.succ, nodes(l.right.child..., ts..., r.left.child...),r.succ),  r.right)
concat(l::FingerTree, r::FingerTree) = app3(l, (), r)
concat(l::FingerTree, x, r::FingerTree) = app3(l, (x,), r)


#=
Base.show(io::IO, d::DigitFT) = print(io, join(d.child, "|"), "|")
Base.show(io::IO, n::Tree23) = len(n) < 20 ? print(io, "^", n.a, "'", n.b, isnull(n.c) ? "" : "'", isnull(n.c) ? "" : get(n.c)) : print(" ... ")
Base.show(io::IO, d::DeepFT) = print(io, "{", d.left, " . ", d.succ, " . ", d.right, "}")
Base.show(io::IO, d::SingleFT) = print(io, "<", d.a, ">")
Base.show(io::IO, d::EmptyFT) = print(io, "{}")
=#
Base.show(io::IO, d::DigitFT) = print(io, join(d.child, " "))
Base.show(io::IO, n::Tree23) = len(n) < 20 ? print(io, n.a, " ", n.b, isnull(n.c) ? "" : " ", isnull(n.c) ? "" : get(n.c)) : print(" ... ")
Base.show(io::IO, d::DeepFT) = print(io, dep(d) == 0 ? "FingerTree[" : "", d.left, " ", d.succ, " ", d.right, dep(d) == 0 ? "]" : "")
Base.show(io::IO, d::SingleFT) = print(io, dep(d) == 0 ? "FingerTree[" : "", d.a, dep(d) == 0 ? "]" : "")
Base.show(io::IO, d::EmptyFT) = print(io, dep(d) == 0 ? "EmptyFT[]" : "")

end
