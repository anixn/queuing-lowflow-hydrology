# Test suite

Run all four test files with the project `drought` Conda environment:

```powershell
python tests/test_queue_core.py
python tests/test_nonstationary_bench.py
python tests/test_rate_estimators.py
python tests/test_real_data_comparison.py
```

Current baseline: 42 tests (12 shared/P01, 6 benchmark, 7 estimator, 17 real-data comparison).
