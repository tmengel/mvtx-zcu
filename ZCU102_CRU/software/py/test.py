from SCA_Comm import ScaComm
gbtfpga = ScaComm()
gbtfpga.configure_fpga("/home/ALICE/ZCU102_CRU/vivado/ZCU102_CRU/ZCU102_CRU.xpr", "/home/ALICE/ZCU102_CRU/ZCU102_CRU_top_210920_1540_1c4b4f39.bit")
gbtfpga.ping()

#gbtfpga.read_vio("countWordReceived")


#gbtfpga.read_ctrl_reg(60)
#gbtfpga.exit()
