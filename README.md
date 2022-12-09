# Gas metrics for [dk1a/solidity-stringutils](https://github.com/dk1a/solidity-stringutils)

This repo is for custom logging tests I use for my optimizations. [Arachnid/solidity-stringutils](https://github.com/Arachnid/solidity-stringutils) is used as a baseline.

## Use

Clone the repo, in it run:
```
yarn install
forge test -vvv
```

## Summary

Default forge gas snapshots can't really measure the efficiency of string/bytes functions, since
1. it's not really well-suited for internal funcs
2. they take dynamic inputs and have various caveats; e.g. for 1000-byte string finding an item at index `0` and index `500` will have very different gas usage.

The logs can be hard to read. The gist of what I've learned so far:
1. [dk1a/solidity-stringutils](https://github.com/dk1a/solidity-stringutils) seems very gas efficient, and it kind of is, except it could be way more efficient for short strings at the sacrifice of usability and readability
2. [Arachnid/solidity-stringutils](https://github.com/Arachnid/solidity-stringutils) isn't designed with solidity 0.8 in mind - no unchecked blocks means the gas use is very inflated. If you add `unchecked` everywhere, most methods become significantly more efficient, and outpace my lib for shortish strings.
3. I have a particularly fast inequality cmp for long strings. For 10000+ bytes `memcmp` is about as fast as `memeq` (i.e. just equality of keccak256 hashes, which is as fast as it gets).
4. `memchr` (and find and its downstream) work particularly well for any strings > ~8 bytes. (they're designed for long strings, and for 8-32 bytes memchr has binary search tricks; but no tricks for memrchr,rfind).
5. Shorter strings are worse mostly due to overhead. Like just calling len() and ptr() wastes ~50 gas everywhere. That's the "usability and readability" part that I'm reluctant to optimize away.
6. memcmp, memchr, memmove etc are fast and have little overhead; you can use them directly if you need to.
7. memmove (i.e. identity precompile) is great but is `view`; memcpy (i.e. chunked mload+mstore) is way worse but is `pure`. I don't use memcpy internally, but it is there if you need it. This is why some methods in Slice and StrSlice are view.
