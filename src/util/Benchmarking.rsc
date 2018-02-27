module util::Benchmarking

import util::Benchmark;
import IO;

tuple[&T, int] bm(&T () methodToBenchmark) {
  int startTime = cpuTime();
  &T result = methodToBenchmark();
  return <result, cpuTime() - startTime>;
}

tuple[&T, int] bm(&T (&R) methodToBenchmark, &R p) {
  int startTime = cpuTime();
  &T result = methodToBenchmark(p);
  return <result, cpuTime() - startTime>;
}

tuple[&T, int] bm(&T (&R,&Q) methodToBenchmark, &R p1, &Q p2) {
  int startTime = cpuTime();
  &T result = methodToBenchmark(p1,p2);
  return <result, cpuTime() - startTime>;
}

tuple[&T, int] bm(&T (&R,&Q,&S) methodToBenchmark, &R p1, &Q p2, &S p3) {
  int startTime = cpuTime();
  &T result = methodToBenchmark(p1,p2,p3);
  return <result, cpuTime() - startTime>;
}

int bmWithPrint(str pr, void (&R,&Q) methodToBenchmark, &R p1, &Q p2) {
  print("<pr>...");
  int startTime = cpuTime();
  &T result = methodToBenchmark(p1,p2);
  print("done in <(cpuTime() - startTime) / 1000000> ms\n");
  return cpuTime() - startTime;
}


tuple[&T, int] bmWithPrint(str pr, &T () methodToBenchmark) {
  print("<pr>...");
  int startTime = cpuTime();
  &T result = methodToBenchmark();
  print("done in <(cpuTime() - startTime) / 1000000> ms\n");
  return <result, cpuTime() - startTime>;
}

tuple[&T, int] bmWithPrint(str pr, &T (&R) methodToBenchmark, &R p) {
  print("<pr>...");
  int startTime = cpuTime();
  &T result = methodToBenchmark(p);
  print("done in <(cpuTime() - startTime) / 1000000> ms\n");
  return <result, cpuTime() - startTime>;
}

tuple[&T, int] bmWithPrint(str pr, &T (&R,&Q) methodToBenchmark, &R p1, &Q p2) {
  print("<pr>...");
  int startTime = cpuTime();
  &T result = methodToBenchmark(p1,p2);
  print("done in <(cpuTime() - startTime) / 1000000> ms\n");
  return <result, cpuTime() - startTime>;
}

tuple[&T, int] bmWithPrint(str pr, &T (&R,&Q,&S) methodToBenchmark, &R p1, &Q p2, &S p3) {
  print("<pr>...");
  int startTime = cpuTime();
  &T result = methodToBenchmark(p1,p2,p3);
  print("done in <(cpuTime() - startTime) / 1000000> ms\n");
  return <result, cpuTime() - startTime>;
}
