# UPDATE STEPS FRIDAY MORNING 

**TURN OFF ALL 2ndary loading** (because lcf,shs,was indexes need rebuilt )


1. upload `augdata`; X
2. upload `scottish-frs-data`; X
3. upload `disabilities`; X
4. julia up
5. git commit
6. run `shs` `lcf` `shs` mergers on new frs;
7. fixup merged shs lcf was code;
8. run weights generation;
9. run local weights generation;
10. weights to  `scottish-frs-data`; rerun 2,3,4
11. Project.toml tag increment
12. git commit
13. git tag matching

**SECONDARY LOADING TURNED ON**

Write unit tests for new disabilities generosity
Write code - switch disability benefits to by age and to Scotland

8. run unit tests
9. eyeball tests on aggregates 
