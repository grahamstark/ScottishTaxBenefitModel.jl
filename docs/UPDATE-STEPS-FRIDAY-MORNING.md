# UPDATE STEPS FRIDAY MORNING 

* **TURN OFF ALL 2ndary loading** (because lcf,shs,was indexes need rebuilt )
* **TURN OFF PRECOMPUTED WEIGHTS**

1. Project.toml tag increment
2. upload `augdata`; X
3. upload `scottish-frs-data`; X
4. upload `disabilities`; X
5. julia up
6. git commit
7. run `shs` `lcf` `shs` mergers on new frs;
8. fixup merged shs lcf was code;
9. run weights generation;
10. run local weights generation;
11. weights to  `scottish-frs-data`; rerun 2,3,4
12. git commit
13. git tag matching

**SECONDARY LOADING TURNED ON**

Write unit tests for new disabilities generosity
Write code - switch disability benefits to by age and to Scotland

14. run unit tests
15. eyeball tests on aggregates 
16. current parameter system check the fuck out of it.
