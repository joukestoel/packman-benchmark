module tests::PackManTester

import PackMan;

void test1() = performRequest(|project://pacman-benchmark/examples/paranoid/install/80e3fda2-9501-11e0-8001-00163e1e087d.cudf|);
void test2() = performRequest(|project://pacman-benchmark/examples/paranoid/install/s-e-l.cudf|);