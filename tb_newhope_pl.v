`timescale 1ns / 1ps
`define P 10
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/21/2020 07:45:16 PM
// Design Name: 
// Module Name: tb_newhope_pl
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_newhope_pl;
    localparam NUM_TESTS = 5;

    reg clk, rst_enc;
    
    reg en_enc, ready_enc;
    wire valid_enc;

    // INPUT
    reg we_c, we_ps, we_pk;
    reg [3:0] addr_c;
    reg [2:0] addr_ps;
    reg [31:0] di_c, di_ps;
    reg [9:0] addr_pk;
    reg [7:0] di_pk;
    
    // OUTPUT
    reg [7:0] baddr_hout;
    reg [9:0] baddr_cout;
    wire [7:0] bdout_h, bdout_c;
    wire step_enc;
    encrypter_pl ENC (clk, rst_enc, en_enc, ready_enc, valid_enc, step_enc,
                        we_c, addr_c, di_c, // coin input
                        we_ps, addr_ps, di_ps, // pubseed input
                        we_pk, addr_pk, di_pk, // pk_poly input
                        baddr_hout, bdout_h, // Compress(V'') out (BYTES)
                        baddr_cout, bdout_c // EncodePoly(A) out (BYTES)c
                        );

    
    reg rst_dec, en_dec, ready_dec;
    wire valid_dec;

    // input signals
    reg bwe_sk, bwe_h, bwe_c;
    reg [9:0] baddr_sk, baddr_c;
    reg [7:0] bdi_sk, bdi_h, bdi_c, baddr_h;
    
    // output signals
    reg [2:0] addr_m;
    wire [31:0] do_m;
    wire step_dec;
    decrypter_pl DEC(clk, rst_dec, en_dec, ready_dec, valid_dec, step_dec,
                    bwe_sk, baddr_sk, bdi_sk, // SK in (BYTES)
                    bwe_h, baddr_h, bdi_h, // Compress(V'') in (BYTES)
                    bwe_c, baddr_c, bdi_c, // EncodePoly(U) in (BYTES)
                    addr_m, do_m // M output
                    );

    // test vectors
    reg [511:0] testvectors [9:0];
    reg [0:255] coin, m, seed;
    integer test_num, error_count, match_count, total_errors;
    integer k;
    reg [31:0] out_check, buffer32;    
    
    reg [0:7167] pk, sk;
    reg [0:255] pubseed;
    
    initial begin
        total_errors = 0;
        match_count = 0;
        error_count = 0;
    
        // initialize signals to zero
        rst_enc   = 0;
        en_enc    = 0;
        ready_enc = 0;
        
        // INPUT ENC
        we_c    = 0; we_ps = 0; we_pk = 0;
        addr_c  = 0; addr_ps = 0;
        di_c    = 0; di_ps = 0;
        addr_pk = 0;
        di_pk   = 0;
        
        // OUTPUT ENC
        baddr_h = 0;
        baddr_c = 0;
        
        // DEC
        en_dec = 0;
        bwe_sk = 0; bwe_h = 0; bwe_c = 0;
        baddr_sk = 0; baddr_c = 0;
        bdi_sk = 0; bdi_h = 0; bdi_c = 0; baddr_h = 0;
        addr_m = 0;
        
        clk = 0;
        ready_dec = 0;
        buffer32 = 0;
        
        test_num = 0;
        error_count = 0;
        match_count = 0;
        total_errors = 0;
        @ (posedge clk);
        rst_enc = 1'b1; rst_dec = 1'b1; #(`P); 
        rst_enc = 1'b0; rst_dec = 1'b0;  #(`P); 
        
        
        
        // Hardcoded test values:
        pk = 7168'h63D500B6532546C29B1CEBFA6204CA6D5ED05EB57081AF70BB5DC0A8C60AB56B6880591B9CBC79E26E4EA7AABE62AE382D4EA6E8B81C3D1A30055A23C5D9848A0D4C4490C24F931F5E45ECFA1008A1FD64F0ACA76109E52B37A153FAEAF1334A191BA455E5CA6A21217B023A83294048F8DE06A031CE4CC1926F265F741829D39B03991C6BF25A8CEB4026BDDA5416B038066B6C4845B3EEC677A12CA40302D5A5F36C7D0A21CD5588A2CEFA78C07A620BD6317E958001A2D14362F4116BD923CB5AD505BCA898EBCB465542E413B1C8ED6BC36AC7B1B3AC6175E7B5C4033655D2CE92B96E4E2540449068C1FA80205AAAE393C93BC25C7DF643AE3130D9F3A7D168985B6AFB03B97814CB1ACE839F6E0B87CA5661B7D6A7DD0195567BF06594891EB627DEA04403516362F16A212E5538FC7D016991981BD31E8C2E6741787E31760149644A6D84A5FDA47C717E8618E90E86E53F563AF50464228A343E3B2BCFCBAE2A480443D1823A6E80EA4D77D84C182338EF12CB63223C59DA26A45C0D86961532A6F46A7FEA53FAFAF1B9730D8F1DA51029B8C91305025641A5A151D3F2D239B93F4B20E550B5AB88D58333651D04C2E301C9B0DA03D82823E7E1984869C6F8BA499EA45D8B0793A8F12553250F773F395A31D627F4AF420D5D95A24287927F5498F302C836011B06D044C7B2AD75124922D52269C09FCDE19CBC73D1642F771DB54331EDEE33902E24E19C58996A66300616CBCA195C99B76D0D70DBE55FBCDBA12BE445185C0196474632409D6CB176CF9862AA616589BFAD1176166F904C418FF611E2B8133AB3B186C95479112AD7603D5527A061B263DA416F221912182225294DA2E4EFAB3515D4959467F4B7FEB6816ADDB66A810528F8CDBD14B5BA47E96BA7BA5CB28482065F30DEF9A155A4C116DAB58F67008D0792858F542E98E5A4E538899A1992E900271EA938F0708D5C1CE5DB71121AB7A21DE8D4DE9857B1ECCC451E9A4E0002E437E7FCA5E4EC39866CA5599C1E17E4D3B01B47EC2348D5EE1F069D8A33EE5E58318A7839C0E5690AAC39799A560B1AD970297A483B721D7F9B93602EE1A80BD9A00D9FAF611AF886246879502D90D395BC1B28D498E5E03591C81582D5C9023C17425B40C085E7D3EED99CD05B68AE57B077495D4BD606572195731D1000332A6579042B2A3099D90B215D4B9A5CE4071EA80464CFC5273150D80217B8797D518C4A497EA180C15830EE2C37EA56240B1D3488;
        pubseed = 256'h1C0EE1111B08003F28E65E8B3BDEB037CF8F221DFCDAF5950EDB38D506D85BEF;
        sk = 7168'h0E4F8531C2099F4204320A84AE494066A04525118B3B88B1C8E4DA5CB3CCD81B47002AC8272956EE190E4D25E0B3B5316F84A270A29EDCB22E4490038076822BCA8E6A37B5982B5DC57B698136769089A8998E3AB3C2EE98765869EC0518F0255226AB9D229226564E7A070E766335106759D5198C7485A1AAC679CFAA8DCEDE4B978A9C558BC5ED53902C54FB58D49649562782A093CAFD46182922A89180E86B526464A2962E2DBBAE386A996CA6CDC6A0E29E1AB86819CC7468A2B32F20D5605D497F704E1F36AC96B8CA2EA0F2EAF54CFE48236408EA8E108310090A105CDAA438DA824A976608F919F2A65977C9E399DD721A7ECBA9969B8CA041405E7037D89F4F6BC38AFD660797AAA9559AF8890A128DDB5A0D2826E529997CB9068F07A1100B6879894AAE375CD852C0DD36D7ED0961701744D42C31ABBE5BF50998F62F87A268348A5D6CAF89E61487B550A8889C93FCF55336C69EA4DF8CBE48E60A81305E2DE282F864FEAD3724A734C398F9759846BA57344D707987BF25ACC54AD499C762C6A0AA17D8BC5673EC6A85CB0F63B7F230A513B538F8253B31DE81642535028BCFC17272ED7221D40613764A852D9A221B1A808B3B55A1088F1960F5427538623CAFDECDFC6719F299BA5DBEE947A17339C7CE77B3F6AAA6C16973BABAB0C4082415AE1C1F44AD27B8C0561397DC6C5AB54D526C07839ABEBC7D0C9B0370076C7852549F837B987B9319F28A85155D065B1341A46612C79A31F3D60D42864BA08856D0B6AC83D6D53804A0B20F45D3218D2B730C5E9B82DD1F0458B364E1E97879AC7CEBEBB816C528A0317BA444B3939CDA378C35C9EBCBC382E15CFCC86DF466602777612509B2197B525A07140221368EC8369AD941B0666C807B89D1235F42EED55C520BBBDB6A0BAA79502F896E958EAD31CA4407080E1A5AE1DEB63923506BDF5F2B21F6C680EEA6AA37F27D3AED4F9785546825469FC850A3659A01C2443A3368AA6F0CFA2880684FD20D9230EC21489EDB0D33EAFD9D6CAA5B5A7E9C03A39F1884E09C2387D809F84D545A9F94EEB9A32DA2312EA610D4317E5BC175D647740C9C45076767D455000100B74A485C886B2BF284DD923E17616ACA263EA56D59BB20DABEBA0408916A8D3F4E6751D463C5433B630FC3B9DD7F9E0B55E8CD52247648F813A1DE960B172C0761C98A20AF8C7022A595C042373055CAAD2D20811783863757A4AC1072A549926B50B6B6054B84AF79016B9A16;
        seed = 256'h7C9935A0B0769FAA0C6D10E4DB6B1ADD2FD81A25CCB148032DCD739936737F2D;
        coin = 256'hA056B4E015FD9EB0237338FB0EFCC59556D9656EDA3A4AEC68F1F2E7B083DF78;
        m    = 256'h000102030405060708090a0b0c0d0E0f101112131415161718191a1b1c1d1e1f;
        
        
        @ (posedge clk);


        
        // read in test data
        $readmemh("D:/programming/NewHopeTrivium/NewHopeCrypto/newhope_tv.txt", testvectors);
        #(`P);
         
        // 2) ENCRYPTION
        en_enc = 1;
        // load message           
        for (k = 0; k < 8; k = k + 1) begin
            addr_c = k+8;
            di_c = m[k*32+:32];
            we_c = 1'b1; #(`P); we_c = 1'b0; #(`P);
        end
        // load pubseed           
        for (k = 0; k < 8; k = k + 1) begin            
            addr_ps = k; // + 8?
            di_ps = pubseed[k*32+:32];
            we_ps = 1'b1; #(`P); we_ps = 1'b0; #(`P);
            
        end
        // load pk
        for (k = 0; k < 896; k = k + 1) begin    
            addr_pk = k;
            di_pk = pk[8*k+:8];
            we_pk = 1'b1; #(`P); we_pk = 1'b0; #(`P);
        end

        // load sk into decrypter
        for (k = 0; k < 896; k = k + 1) begin        
            baddr_sk = k;
            bdi_sk = sk[k*8+:8];
            bwe_sk = 1'b1; #(`P); bwe_sk = 1'b0; #(`P);
        end
        
       // $stop;
        
        rst_enc = 1'b1; #(`P); rst_enc = 1'b0; #(`P); 
        for (test_num = 0; test_num < NUM_TESTS; test_num=test_num+1) begin
            coin = testvectors[test_num][255:0];

            // load coin           
            for (k = 0; k < 8; k = k + 1) begin
                addr_c = k;
                di_c = coin[k*32+:32];
                we_c = 1'b1; #(`P); we_c = 1'b0; #(`P);
            end
            //stop;
            $display("Start Encryption"); 
            ready_enc = 1'b1; #(`P);  ready_enc = 1'b0; #(`P);    
            while (step_enc == 1'b1) #(`P);
            
               
        end
        
        while (valid_enc != 1) #(`P);
        $display("Encryption valid"); #50;
        en_enc = 0; 
//        $stop;
        
        en_dec = 1; #(`P);
        rst_dec = 1'b1; #(`P); rst_dec = 1'b0; #(`P);
        for (test_num = 0; test_num < NUM_TESTS; test_num=test_num+1) begin    
            // 3) DECRYPTION
            // load ct poly into decrypter
            
            for (k = 0; k < 896; k = k + 1) begin                
                if (k < 192) begin
                    baddr_hout = k; baddr_cout = k; #(`P);
                    bdi_c = bdout_c;
                    baddr_c = k;
                    
                    bdi_h = bdout_h;
                    baddr_h = k;
                    bwe_c = 1'b1; bwe_h = 1'b1; #(`P); bwe_c = 1'b0;  bwe_h = 1'b0;#(`P);
                end else begin
                    baddr_cout = k; #(`P);
                    bdi_c = bdout_c;
                    baddr_c = k;
                
                    bwe_h = 0;
                    bwe_c = 1'b1; #(`P); bwe_c = 1'b0; #(`P);
                end
            end
            
//            $stop;
            $display("Start Decryption"); 
            
            ready_dec = 1'b1; #(`P);  ready_dec = 1'b0; #(`P); 
            while (step_dec == 1'b1) #(`P);
            
            en_enc = 1;
            while (step_enc == 1'b1) #(`P);
            #50;
            en_enc = 0;
        end
        
        while (valid_dec != 1) #(`P);
        $display("Decryption valid"); 
        en_dec = 0; #(`P);
        
        for (test_num = 0; test_num < NUM_TESTS; test_num=test_num+1) begin               
            // 4) CHECK RESULTS ** WILL NOT MATCH UNTIL DECAPS IS ADDED)
            #(`P);
            error_count = 0;
            match_count = 0;
            for (k = 0; k < 8; k=k+1) begin
                out_check = m[k*32+:32];
                addr_m = k; #(`P);
                if (out_check !== do_m) begin
                    error_count = error_count  + 1;
                    $display("Error at entry %d: %h %h", k, out_check, do_m); 
                    total_errors = total_errors + 1;
                end
                else begin
                    match_count = match_count  + 1;
                    $display("Match at entry %d: %h %h", k, out_check, do_m);
                end
                
                #(`P);
            end
            $display("Done checking test %d. Correct: %d, Errors: %d", test_num, match_count, error_count);
            
            en_dec = 1;
//            $stop;
            while (step_dec == 1'b1) #(`P);
            en_dec = 0;
        end
            


        $display("Total errors: %d", total_errors);
        
        $finish;
    end
    
    always #(`P/2) clk = ~ clk;

endmodule
`undef P