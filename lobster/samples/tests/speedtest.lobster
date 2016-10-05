include "unittest.lobster"

starttime := seconds_elapsed()
for(1000):
    run_test_cases()
print(seconds_elapsed() - starttime)
