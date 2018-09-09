//========================================================================
// Test Cases for mul instruction
//========================================================================
// this file is to be `included by plab2-proc-test-harness.v


//------------------------------------------------------------------------
// Basic tests
//------------------------------------------------------------------------

task init_mul_basic;
begin
  clear_mem;

  address( c_reset_vector );
  inst( "mfc0 r1, mngr2proc " ); init_src(  32'h00000005 );
  inst( "mfc0 r2, mngr2proc " ); init_src(  32'h00000004 );
  inst( "nop                " );
  inst( "nop                " );
  inst( "nop                " );
  inst( "nop                " );
  inst( "nop                " );
  inst( "mul r3, r2, r1     " );
  inst( "nop                " );
  inst( "nop                " );
  inst( "nop                " );
  inst( "nop                " );
  inst( "nop                " );
  inst( "mtc0 r3, proc2mngr " ); init_sink( 32'h00000014 );
  inst( "nop                " );
  inst( "nop                " );
  inst( "nop                " );
  inst( "nop                " );
  inst( "nop                " );
  inst( "nop                " );
  inst( "nop                " );

end
endtask

// add more test vectors here

//------------------------------------------------------------------------
// Bypassing tests
//------------------------------------------------------------------------

task init_mul_bypass;
begin
  clear_mem;

  address( c_reset_vector );

  test_rr_dest_byp( 0, "mul", 4, 5, 20 );
  test_rr_dest_byp( 1, "mul", 4, 2, 8 );
  test_rr_dest_byp( 2, "mul", 5, 3, 15 );

  test_rr_src01_byp( 0, 0, "mul", 13, 11, 143 );
  test_rr_src01_byp( 0, 1, "mul", 14, 11, 154 );
  test_rr_src01_byp( 0, 2, "mul", 15, 11, 165 );
  test_rr_src01_byp( 1, 0, "mul", 13, 11, 143 );
  test_rr_src01_byp( 1, 1, "mul", 14, 11, 154 );
  test_rr_src01_byp( 2, 0, "mul", 15, 11, 165 );

  test_rr_src10_byp( 0, 0, "mul", 13, 11, 143 );
  test_rr_src10_byp( 0, 1, "mul", 14, 11, 154 );
  test_rr_src10_byp( 0, 2, "mul", 15, 11, 165 );
  test_rr_src10_byp( 1, 0, "mul", 13, 11, 143 );
  test_rr_src10_byp( 1, 1, "mul", 14, 11, 154 );
  test_rr_src10_byp( 2, 0, "mul", 15, 11, 165 );

  test_insert_nops( 8 );

end
endtask


//------------------------------------------------------------------------
// Value tests
//------------------------------------------------------------------------

task init_mul_value;
begin
  clear_mem;

  address( c_reset_vector );

  //----------------------------------------------------------------------
  // Arithmetic tests
  //----------------------------------------------------------------------

  test_rr_op( "mul", 32'h00000000, 32'h00000000, 32'h00000000 );
  test_rr_op( "mul", 32'h00000001, 32'h00000001, 32'h00000001 );
  test_rr_op( "mul", 32'h00000003, 32'h00000007, 32'h00000015 );

  test_rr_op( "mul", 32'h00000000, 32'hffff8000, 32'h00000000 );
  test_rr_op( "mul", 32'h80000000, 32'h00000000, 32'h00000000 );
  test_rr_op( "mul", 32'h00000000, 32'hffff8000, 32'h00000000 );

  test_rr_op( "mul", 32'h00000000, 32'h00007fff, 32'h00000000 );
  test_rr_op( "mul", 32'h7fffffff, 32'h00000000, 32'h00000000 );
  test_rr_op( "mul", 32'h00000000, 32'h00007fff, 32'h00000000 );

  test_rr_op( "mul", 32'h00000012, 32'h00000003, 32'h00000036 );
  test_rr_op( "mul", 32'h00000004, 32'h00000018, 32'h00000060 );

  test_rr_op( "mul", 32'h00000000, 32'hffffffff, 32'h00000000 );
  test_rr_op( "mul", 32'hffffffff, 32'h00000001, 32'hffffffff );
  test_rr_op( "mul", 32'h00000000, 32'hffffffff, 32'h00000000 );

  //----------------------------------------------------------------------
  // Source/Destination tests
  //----------------------------------------------------------------------

  test_rr_src0_eq_dest( "mul", 13, 11, 143 );
  test_rr_src1_eq_dest( "mul", 14, 11, 154 );
 // test_rr_src0_eq_src1( "mul", 15, 30 );
 // test_rr_srcs_eq_dest( "mul", 16, 32 );


  test_insert_nops( 8 );

end
endtask

//------------------------------------------------------------------------
// Long tests
//------------------------------------------------------------------------

integer idx;
task init_mul_long;
begin
  clear_mem;

  address( c_reset_vector );

  for ( idx = 0; idx < 100; idx = idx + 1 ) begin
    test_rr_op( "mul", 32'h00000001, 32'h00000002, 32'h00000002 );
    test_rr_op( "mul", 32'h00000003, 32'h00000007, 32'h00000015 );
  end

  test_insert_nops( 8 );

end
endtask



//------------------------------------------------------------------------
// Test Case: mul basic
//------------------------------------------------------------------------

`VC_TEST_CASE_BEGIN( 1, "mul basic" )
begin
  init_rand_delays( 0, 0, 0 );
  init_mul_basic;
  run_test;
end
`VC_TEST_CASE_END

// add more test cases here

//------------------------------------------------------------------------
// Test Case: mul bypass
//------------------------------------------------------------------------

`VC_TEST_CASE_BEGIN( 2, "mul bypass" )
begin
  init_rand_delays( 0, 0, 0 );
  init_mul_bypass;
  run_test;
end
`VC_TEST_CASE_END

//------------------------------------------------------------------------
// Test Case: addu value
//------------------------------------------------------------------------

`VC_TEST_CASE_BEGIN( 3, "mul value" )
begin
  init_rand_delays( 0, 0, 0 );
  init_mul_value;
  run_test;
end
`VC_TEST_CASE_END

//------------------------------------------------------------------------
// Test Case: addu stalls/bubbles
//------------------------------------------------------------------------

`VC_TEST_CASE_BEGIN( 4, "mul stalls/bubbles" )
begin
  init_rand_delays( 4, 4, 4 );
  init_mul_long;
  run_test;
end
`VC_TEST_CASE_END




