//Module: forward mux
//Function: This mux selects the right input for the alu block when forwarding
//Inputs:
//input_0 (16 bits):  
//input_1 (16 bits): 
//input_2 (16 bits): 
//selection (2 bits): Picks the right signal, comes from detection block
//Outputs:
//mux_out (16 bits): The input that needs to go to the alu block


module mux_forwarding
  #(
   parameter integer DATA_W = 16
   )(
      input  wire [DATA_W-1:0] input_0, //regular input
      input  wire [DATA_W-1:0] input_1, 
      input  wire [DATA_W-1:0] input_2, 
      input  wire [1:0]        selection,
      output reg  [DATA_W-1:0] mux_out
   );

   always@(*)begin

      if(selection == 2'b0)
      begin
         mux_out = input_0;
      end 
      
      else if (selection == 2'b1) 
      begin
         mux_out = input_1;
      end 
      
      else
      begin
         mux_out = input_2;
      end
         
   end
endmodule
