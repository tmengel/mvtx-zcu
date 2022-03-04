function logic [n-1:0] encode_f(logic [k-1:0] in_vector);
   begin
      logic [n:1] encoded_v;
      if (n == 7) begin
         //redundant
         encoded_v[1] = ^{in_vector[3], in_vector[1], in_vector[0]};
         encoded_v[2] = ^{in_vector[3], in_vector[2], in_vector[0]};
         encoded_v[4] = ^{in_vector[3], in_vector[2], in_vector[1]};

         //info vector
         encoded_v[3] = in_vector[0];
         encoded_v[7:5] = in_vector[3:1];

      end else if (n == 15) begin
         encoded_v[1] = ^{in_vector[10], in_vector[8], in_vector[6], in_vector[4], in_vector[3], in_vector[1], in_vector[0]};
         encoded_v[2] = ^{in_vector[10], in_vector[9], in_vector[6], in_vector[5], in_vector[3], in_vector[2], in_vector[0]};
         encoded_v[4] = ^{in_vector[10], in_vector[9], in_vector[8], in_vector[7], in_vector[3], in_vector[2], in_vector[1]};
         encoded_v[8] = ^{in_vector[10], in_vector[9], in_vector[8], in_vector[7], in_vector[6], in_vector[5], in_vector[4]};

         //info vector
         encoded_v[3] = in_vector[0];
         encoded_v[7:5] = in_vector[3:1];
         encoded_v[15:9] = in_vector[10:4];
      end

      return encoded_v;
   end
endfunction // encode_f

// function logic parity_encode_f(logic [n-1:0] in_vector);
//    begin
//       return ^in_vector;
//    end
// endfunction // encode_ded_f

/* -----\/----- EXCLUDED -----\/-----
function logic [n:0] encode_ded_f(logic [k-1:0] in_vector);
   begin
      logic [n:0] encoded_v;
      encoded_v[n-1:0] encode_f(in_vector);
      encoded_v[n] = {parity_encode_f(encoded_v)};
      return encoded_v;
   end
endfunction
 -----/\----- EXCLUDED -----/\----- */

function logic [k-1:0] decode_f(logic [n-1:0] encoded_vector);
   begin
      logic [k-1:0] decoded_v;
      logic [n:1]   encoded_v;
      encoded_v = encoded_vector;
      if (n==7) begin
         decoded_v[0]  = encoded_v[3];
         decoded_v[1]  = encoded_v[5];
         decoded_v[2]  = encoded_v[6];
         decoded_v[3]  = encoded_v[7];
      end else if (n == 15) begin
         decoded_v[0]  = encoded_v[3];
         decoded_v[1]  = encoded_v[5];
         decoded_v[2]  = encoded_v[6];
         decoded_v[3]  = encoded_v[7];
         decoded_v[4]  = encoded_v[9];
         decoded_v[5]  = encoded_v[10];
         decoded_v[6]  = encoded_v[11];
         decoded_v[7]  = encoded_v[12];
         decoded_v[8]  = encoded_v[13];
         decoded_v[9]  = encoded_v[14];
         decoded_v[10] = encoded_v[15];
      end
      return decoded_v;
   end
endfunction // decode_f
