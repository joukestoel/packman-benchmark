module tests::PackManTester

import PackMan;
import util::Statistics;

private loc testBase() = |file:///Users/jouke/workspace/packman-benchmark/examples/paranoid|;

Statistic testInstall1() = performRequest(testBase() + "/install/80e3fda2-9501-11e0-8001-00163e1e087d.cudf");
Statistic testInstall2() = performRequest(testBase() + "/install/3e4f8550-0b33-11df-942d-00163e1d94dc.cudf");

Statistic testUpgrade1() = performRequest(testBase() + "/upgrade/caefdef6-3477-11e0-84ef-00163e3d3b7c.cudf");

void checkAllExampleInstallFiles() = runAllFilesInDir(testBase() + "/install");
