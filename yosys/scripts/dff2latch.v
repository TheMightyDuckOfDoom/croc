/// Maps a Flip-Flop to two latches
module \$_DFF_PN0_ ( D, C, R, Q);
    input  D, C, R;
    output Q;

    wire mst_q;

    sg13g2_dllrq_1 i_mst (
        .GATE_N ( C     ),
        .D      ( D     ),
        .RESET_B( R     ),
        .Q      ( mst_q )
    );

    sg13g2_dlhq_1 i_sub (
        .GATE( C     ),
        .D   ( mst_q ),
        .Q   ( Q     )
    );

endmodule