//========================================================================
// Test Cases for jr instruction
//========================================================================
// this file is to be `included by plab2-proc-test-harness.v

//------------------------------------------------------------------------
// Basic tests
//------------------------------------------------------------------------

task init_jr_basic;
begin

  clear_mem;

  address( c_reset_vector );
  inst( "mfc0  r3, mngr2proc"); init_src( 32'h00000001 );
  // send the target pc
  inst( "mfc0  r2, proc2mngr"); init_src( c_reset_vector + 15 * 4 );
  inst( "nop                ");
  inst( "nop                ");
  inst( "nop                ");
  inst( "nop                ");
  inst( "nop                ");
  inst( "jr    r2           "); // goto 1:
  // send zero if fail
  inst( "mtc0  r0, proc2mngr"); // we don't expect a message here
  inst( "nop                ");
  inst( "nop                ");
  inst( "nop                ");
  inst( "nop                ");
  inst( "nop                ");
  inst( "nop                ");

  // 1:
  // pass
  inst( "mtc0  r3, proc2mngr"); init_sink( 32'h00000001 );

  inst( "nop                ");
  inst( "nop                ");
  inst( "nop                ");
  inst( "nop                ");
  inst( "nop                ");
  inst( "nop                ");

end
endtask

// add more test vectors here

//------------------------------------------------------------------------
// Misc tests
//------------------------------------------------------------------------

task init_jr_misc;
begin

  clear_mem;

  address( c_reset_vector );

  inst( "mfc0  r3, mngr2proc"); init_src( 32'h00000001 );
  inst( "mfc0  r2, proc2mngr"); init_src( c_reset_vector + 10 * 4 );
  inst( "nop                ");
  inst( "nop                ");
  inst( "nop                ");
  inst( "nop                ");
  inst( "jr    r2           "); // goto 1:
  inst( "mtc0  r0, proc2mngr"); // we don't expect a message here
  inst( "nop                ");

  // 1:
  // pass
  inst( "mtc0  r3, proc2mngr"); init_sink( 32'h00000001 );
  inst( "mfc0  r2, proc2mngr"); init_src( c_reset_vector + 14 * 4 );
  inst( "jr    r2           "); // goto 1:
  // fail
  inst( "mtc0  r0, proc2mngr");

  // 2:
  // pass
  inst( "mtc0  r3, proc2mngr"); init_sink( 32'h00000001 );
  inst( "mfc0  r2, proc2mngr"); init_src( c_reset_vector + 18 * 4 );
  inst( "jr    r2           "); // goto 1:
  // fail
  inst( "mtc0  r0, proc2mngr");
  // 3:
  // pass
  inst( "mtc0  r3, proc2mngr"); init_sink( 32'h00000001 );

  // test branch's priority over jump
  inst( "mfc0  r2, proc2mngr"); init_src( c_reset_vector + 23 * 4 );
  inst( "jr    r2           "); // goto 1:
  inst( "mtc0  r0, proc2mngr");

  // 4:
  // fail
  inst( "nop                ");
  inst( "nop                ");
  inst( "nop                ");
  inst( "nop                ");
  inst( "mtc0  r3, proc2mngr"); init_sink( 32'h00000001 );

  inst( "nop                ");
  inst( "nop                ");
  inst( "nop                ");
  inst( "nop                ");
  inst( "nop                ");
  inst( "nop                ");

end
endtask



//------------------------------------------------------------------------
// Long test
//------------------------------------------------------------------------

integer idx;
task init_jr_long;
begin

  clear_mem;

  address( c_reset_vector );
  inst( "mfc0  r3, mngr2proc"); init_src( 32'h00000001 );
  for ( idx = 0; idx < 10; idx = idx + 1 ) begin
  inst( "mfc0  r1, mngr2proc"); init_src( c_reset_vector + 9 * 4 );
  inst( "mfc0  r2, proc2mngr"); init_src( c_reset_vector + 5 * 4 );
  
  inst( "jr    r2           "); // goto 1:
  inst( "mtc0  r0, proc2mngr"); // we don't expect a message here  
  inst( "nop                ");  
  inst( "jr    r1           "); // goto 1:
  inst( "mtc0  r0, proc2mngr"); // we don't expect a message here
  
  inst( "nop                ");
  inst( "nop                ");
  inst( "mtc0  r3, proc2mngr"); init_sink( 32'h00000001 );

  end

end
endtask



//------------------------------------------------------------------------
// Test Case: jr basic
//------------------------------------------------------------------------

`VC_TEST_CASE_BEGIN(1, "jr basic" )
begin
  init_rand_delays( 0, 0, 0 );
  init_jr_basic;
  run_test;
end
`VC_TEST_CASE_END

// add more test cases here

//------------------------------------------------------------------------
// Test Case: j misc
//------------------------------------------------------------------------

`VC_TEST_CASE_BEGIN(2, "jr misc" )
begin
  init_rand_delays( 0, 0, 0 );
  init_jr_misc;
  run_test;
end
`VC_TEST_CASE_END



//------------------------------------------------------------------------
// Test Case: j stalls/bubbles
//------------------------------------------------------------------------

`VC_TEST_CASE_BEGIN(3, "j stalls/bubbles" )
begin
  init_rand_delays( 4, 4, 4 );
  init_jr_long;
  run_test;
end
`VC_TEST_CASE_END


