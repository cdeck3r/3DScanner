# Housekeeping

The housekeeping process works as follows:

1. Check for free space. Parameter `low watermark` defines the permitted lower bound.
1. In case, we are below the low watermark, we start deleting the oldest files from a given directory until we are above the `high watermark` parameter.

It is `low watermark < high watermark`. The process basically defines a hysteresis. 

Documentation: [docs/logging_housekeeping.md](../../docs/logging_housekeeping.md)

Relevant scripts:

* `housekeeping.sh`
* `install_housekeeping.sh`
* ...

### Unit testing

Since housekeeping deletes files, it is important to test the tool before putting it into production.

```bash
cd tests
./testrunner.sh
```

