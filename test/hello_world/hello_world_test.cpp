#include <catch2/catch_all.hpp>
#include <hello_world.hpp>

TEST_CASE("test of test") {
  CHECK_NOTHROW(template_project::helloWorld());
}