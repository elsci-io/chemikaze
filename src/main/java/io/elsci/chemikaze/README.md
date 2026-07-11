How to store bonds
------------------

2 common approaches are:
- `int[] bonds` which is doesn't allow us to find bonds of a particular atom. We have to iterate over all elements.
- `int[][] bonds` where 1st index is the `atomIdx`. Allows finding the bonds of a particular atom. But requires storing
x2 values as we need to connect atoms A->B and B->A.

# Implementing `int[][] bonds`

In Java each 2nd dimension array can be allocated separately, so `bonds[1]` can be length 3, while `bonds[2]`
can be length 5. But this is inefficient: it leads to many small allocations and memory fragmentation.

Instead we can allocate `int[atomCnt][4] bonds` of continuous memory: 
- non-filled elements mean there's no bond
- if we have more than 4 bonds, we need an extra array for extra bonds

When an `int[]` is created, it's filled with 0's. How do we tell apart "references 0th atom" and "this bond isn't filled":
- Either start all arrays with 1, and 0 means "not initialized"
- Or fill the bonds with -1's
- Or keep `byte[] bondCount`