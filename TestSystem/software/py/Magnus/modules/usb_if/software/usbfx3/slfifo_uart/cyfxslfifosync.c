/*
 ## Cypress USB 3.0 Platform source file (cyfxslfifosync.c)
 ## ===========================
 ##
 ##  Copyright Cypress Semiconductor Corporation, 2010-2011,
 ##  All Rights Reserved
 ##  UNPUBLISHED, LICENSED SOFTWARE.
 ##
 ##  CONFIDENTIAL AND PROPRIETARY INFORMATION
 ##  WHICH IS THE PROPERTY OF CYPRESS.
 ##
 ##  Use of this file is governed
 ##  by the license agreement included in the file
 ##
 ##     <install>/license/license.txt
 ##
 ##  where <install> is the Cypress software
 ##  installation root directory path.
 ##
 ## ===========================
*/

/* This file illustrates the Slave FIFO Synchronous mode example */

/*
   This example comprises of two USB bulk endpoints. A bulk OUT endpoint acts as
   the
   producer of data from the host. A bulk IN endpoint acts as the consumer of
   data to
   the host. Appropriate vendor class USB enumeration descriptors with these two
   bulk
   endpoints are implemented.

   The GPIF configuration data for the Synchronous Slave FIFO operation is
   loaded onto
   the appropriate GPIF registers. The p-port data transfers are done via the
   producer
   p-port socket and the consumer p-port socket.

   This example implements two DMA Channels in MANUAL mode one for P to U data
   transfer
   and one for U to P data transfer.

   The U to P DMA channel connects the USB producer (OUT) endpoint to the
   consumer p-port
   socket. And the P to U DMA channel connects the producer p-port socket to the
   USB
   consumer (IN) endpoint.

   Upon every reception of data in the DMA buffer from the host or from the
   p-port, the
   CPU is signalled using DMA callbacks. There are two DMA callback functions
   implemented
   each for U to P and P to U data paths. The CPU then commits the DMA buffer
   received so
   that the data is transferred to the consumer.

   The DMA buffer size for each channel is defined based on the USB speed. 64
   for full
   speed, 512 for high speed and 1024 for super speed.
   CY_FX_SLFIFO_DMA_BUF_COUNT in the
   header file defines the number of DMA buffers per channel.

   The constant CY_FX_SLFIFO_GPIF_16_32BIT_CONF_SELECT in the header file is
   used to
   select 16bit or 32bit GPIF data bus configuration.
 */

#include "cyu3system.h"
#include "cyu3os.h"
#include "cyu3dma.h"
#include "cyu3error.h"
#include "cyu3usb.h"
#include "cyu3uart.h"
#include "cyfxslfifosync.h"
#include "cyu3gpif.h"
#include "cyu3pib.h"
#include "pib_regs.h"

/* This file should be included only once as it contains
 * structure definitions. Including it in multiple places
 * can result in linker error. */
#include "cyfxgpif2config.h"


CyU3PThread USBAppThread;

CyU3PDmaChannel
glChHandleConsumerFifo; /* DMA Channel handle for U2P transfer. */
CyU3PDmaChannel
glChHandleProducerFifoA; /* DMA Channel handle for P2U transfer. */
CyU3PDmaChannel
glChHandleProducerFifoB; /* DMA Channel handle for P2U transfer. */
CyU3PDmaChannel
glChHandleProducerFifoC; /* DMA Channel handle for P2U transfer. */

/* USB UART */
/* DMA AUTO (USB TO UART) channel handle.*/
CyU3PDmaChannel glChHandleUsbtoUart;
/* DMA AUTO_SIG(UART TO USB) channel handle.*/
CyU3PDmaChannel glChHandleUarttoUsb;

/* Counter to track the number of buffers received from USB. */
uint32_t glDMARxCount = 0;
/* Counter to track the number of buffers sent to USB. */
uint32_t glDMATxCount = 0;
/* Whether the loopback application is active or not. */
CyBool_t glIsApplnActive = CyFalse;

CyU3PUartConfig_t glUartConfig = { 0 }; /* Current UART configuration. */
volatile uint16_t glPktsPending =
    0; /* Number of packets that have been committed since last check. */

/* CDC Class specific requests to be handled by this application. */
#define SET_LINE_CODING 0x20
#define GET_LINE_CODING 0x21
#define SET_CONTROL_LINE_STATE 0x22

/* Application Error Handler */
void
CyFxAppErrorHandler(CyU3PReturnStatus_t apiRetStatus /* API return status */
                    ) {
  /* Application failed with the error code apiRetStatus */

  /* Add custom debug or recovery actions here */

  /* Loop Indefinitely */
  for (;;) {
    /* Thread sleep : 100 ms */
    CyU3PThreadSleep(100);
  }
}

/* DMA Callbacks */

/* DMA callback function for Uart transfers */
void CyFxUSBUARTDmaCallback(CyU3PDmaChannel *chHandle, CyU3PDmaCbType_t type,
                            CyU3PDmaCBInput_t *input) {
  if (type == CY_U3P_DMA_CB_PROD_EVENT) {
    CyU3PDmaChannelCommitBuffer(&glChHandleUarttoUsb, input->buffer_p.count, 0);
    glPktsPending++;
  }
}

/* This function starts the USBUART application */
void CyFxUSBUARTAppStart(uint16_t size) {
  CyU3PEpConfig_t epCfg;
  CyU3PDmaChannelConfig_t dmaCfg;
  CyU3PReturnStatus_t apiRetStatus = CY_U3P_SUCCESS;

  CyU3PMemSet((uint8_t *)&epCfg, 0, sizeof(epCfg));
  epCfg.enable = CyTrue;
  epCfg.epType = CY_U3P_USB_EP_BULK;
  epCfg.burstLen = 1;
  epCfg.streams = 0;
  epCfg.pcktSize = size;

  /* Producer endpoint configuration */
  apiRetStatus = CyU3PSetEpConfig(CY_FX_EP_UARTOUT, &epCfg);
  if (apiRetStatus != CY_U3P_SUCCESS) {
    CyFxAppErrorHandler(apiRetStatus);
  }

  /* Consumer endpoint configuration */
  apiRetStatus = CyU3PSetEpConfig(CY_FX_EP_UARTIN, &epCfg);
  if (apiRetStatus != CY_U3P_SUCCESS) {
    CyFxAppErrorHandler(apiRetStatus);
  }

  /* Interrupt endpoint configuration */
  epCfg.epType = CY_U3P_USB_EP_INTR;
  epCfg.pcktSize = 64;
  epCfg.isoPkts = 1;

  apiRetStatus = CyU3PSetEpConfig(CY_FX_EP_INTERRUPT, &epCfg);
  if (apiRetStatus != CY_U3P_SUCCESS) {
    CyFxAppErrorHandler(apiRetStatus);
  }

  /* Create a DMA_AUTO channel between usb producer socket and uart consumer
   * socket */
  dmaCfg.size = size;
  dmaCfg.count = CY_FX_USBUART_DMA_BUF_COUNT;
  dmaCfg.prodSckId = CY_FX_EP_PRODUCER1_SOCKET;
  dmaCfg.consSckId = CY_FX_EP_CONSUMER1_SOCKET;
  dmaCfg.dmaMode = CY_U3P_DMA_MODE_BYTE;
  dmaCfg.notification = 0;
  dmaCfg.cb = NULL;
  dmaCfg.prodHeader = 0;
  dmaCfg.prodFooter = 0;
  dmaCfg.consHeader = 0;
  dmaCfg.prodAvailCount = 0;

  apiRetStatus = CyU3PDmaChannelCreate(&glChHandleUsbtoUart,
                                       CY_U3P_DMA_TYPE_AUTO, &dmaCfg);
  if (apiRetStatus != CY_U3P_SUCCESS) {
    CyFxAppErrorHandler(apiRetStatus);
  }

  /* Create a DMA_MANUAL channel between uart producer socket and usb consumer
   * socket */
  /* Use a smaller buffer size (32 bytes) to ensure that packets get filled in a
   * short time. */
  dmaCfg.size = 32;
  dmaCfg.prodSckId = CY_FX_EP_PRODUCER2_SOCKET;
  dmaCfg.consSckId = CY_FX_EP_CONSUMER2_SOCKET;
  dmaCfg.notification = CY_U3P_DMA_CB_PROD_EVENT;
  dmaCfg.cb = CyFxUSBUARTDmaCallback;

  apiRetStatus = CyU3PDmaChannelCreate(&glChHandleUarttoUsb,
                                       CY_U3P_DMA_TYPE_MANUAL, &dmaCfg);
  if (apiRetStatus != CY_U3P_SUCCESS) {
    CyFxAppErrorHandler(apiRetStatus);
  }

  /* Set DMA Channel transfer size */
  apiRetStatus = CyU3PDmaChannelSetXfer(&glChHandleUsbtoUart, 0);
  if (apiRetStatus != CY_U3P_SUCCESS) {
    CyFxAppErrorHandler(apiRetStatus);
  }

  apiRetStatus = CyU3PDmaChannelSetXfer(&glChHandleUarttoUsb, 0);
  if (apiRetStatus != CY_U3P_SUCCESS) {
    CyFxAppErrorHandler(apiRetStatus);
  }
}

void CyFxUSBUARTAppStop(void) {
  CyU3PEpConfig_t epCfg;
  CyU3PReturnStatus_t apiRetStatus = CY_U3P_SUCCESS;

  /* Flush the endpoint memory */
  CyU3PUsbFlushEp(CY_FX_EP_UARTOUT);
  CyU3PUsbFlushEp(CY_FX_EP_UARTIN);
  CyU3PUsbFlushEp(CY_FX_EP_INTERRUPT);

  /* Destroy the channel */
  CyU3PDmaChannelDestroy(&glChHandleUsbtoUart);
  CyU3PDmaChannelDestroy(&glChHandleUarttoUsb);

  /* Disable endpoints. */
  CyU3PMemSet((uint8_t *)&epCfg, 0, sizeof(epCfg));
  epCfg.enable = CyFalse;

  /* Producer endpoint configuration. */
  apiRetStatus = CyU3PSetEpConfig(CY_FX_EP_UARTOUT, &epCfg);
  if (apiRetStatus != CY_U3P_SUCCESS) {
    CyFxAppErrorHandler(apiRetStatus);
  }

  /* Consumer endpoint configuration. */
  apiRetStatus = CyU3PSetEpConfig(CY_FX_EP_UARTIN, &epCfg);
  if (apiRetStatus != CY_U3P_SUCCESS) {
    CyFxAppErrorHandler(apiRetStatus);
  }

  /* Interrupt endpoint configuration. */
  apiRetStatus = CyU3PSetEpConfig(CY_FX_EP_INTERRUPT, &epCfg);
  if (apiRetStatus != CY_U3P_SUCCESS) {
    CyFxAppErrorHandler(apiRetStatus);
  }
}

/* This function starts the slave FIFO loop application. This is called
 * when a SET_CONF event is received from the USB host. The endpoints
 * are configured and the DMA pipe is setup in this function. */
void CyFxSlFifoApplnStart(uint16_t size) {
  CyU3PEpConfig_t epCfg;
  CyU3PDmaChannelConfig_t dmaCfg;
  CyU3PReturnStatus_t apiRetStatus = CY_U3P_SUCCESS;

  CyU3PMemSet((uint8_t *)&epCfg, 0, sizeof(epCfg));
  epCfg.enable = CyTrue;
  epCfg.epType = CY_U3P_USB_EP_BULK;
  epCfg.burstLen = 1;
  epCfg.streams = 0;
  epCfg.pcktSize = size;

  /* Producer endpoint configuration */
  apiRetStatus = CyU3PSetEpConfig(CY_FX_EP_PRODUCER, &epCfg);
  if (apiRetStatus != CY_U3P_SUCCESS) {
    CyFxAppErrorHandler(apiRetStatus);
  }
  /* Consumer endpoint configuration */
  // A
  apiRetStatus = CyU3PSetEpConfig(CY_FX_EP_CONSUMER_A, &epCfg);
  if (apiRetStatus != CY_U3P_SUCCESS) {
    CyFxAppErrorHandler(apiRetStatus);
  }
  // B
  apiRetStatus = CyU3PSetEpConfig(CY_FX_EP_CONSUMER_B, &epCfg);
  if (apiRetStatus != CY_U3P_SUCCESS) {
    CyFxAppErrorHandler(apiRetStatus);
  }
  // C
  apiRetStatus = CyU3PSetEpConfig(CY_FX_EP_CONSUMER_C, &epCfg);
  if (apiRetStatus != CY_U3P_SUCCESS) {
    CyFxAppErrorHandler(apiRetStatus);
  }

  /* Create a DMA AUTO channel for U2P transfer.
   * DMA size is set based on the USB speed. */
  dmaCfg.size = size;
  dmaCfg.count = CY_FX_SLFIFO_DMA_BUF_COUNT;
  dmaCfg.prodSckId = CY_FX_PRODUCER_USB_SOCKET;
  dmaCfg.consSckId = CY_FX_CONSUMER_PPORT_SOCKET;
  dmaCfg.dmaMode = CY_U3P_DMA_MODE_BYTE;
  /* Enabling the callback for produce event. */
  dmaCfg.notification = 0; // CY_U3P_DMA_CB_PROD_EVENT;
  dmaCfg.cb = 0;           // CyFxSlFifoUtoPDmaCallback;
  dmaCfg.prodHeader = 0;
  dmaCfg.prodFooter = 0;
  dmaCfg.consHeader = 0;
  dmaCfg.prodAvailCount = 0;

  apiRetStatus = CyU3PDmaChannelCreate(
      &glChHandleConsumerFifo, CY_U3P_DMA_TYPE_AUTO /*CY_U3P_DMA_TYPE_MANUAL*/,
      &dmaCfg);
  if (apiRetStatus != CY_U3P_SUCCESS) {
    CyU3PDebugPrint(4, "CyU3PDmaChannelCreate failed, Error code = %d\n",
                    apiRetStatus);
    CyFxAppErrorHandler(apiRetStatus);
  }

  /* Create a DMA AUTO channel for P2U transfer. */
  // A
  dmaCfg.prodSckId = CY_FX_PRODUCER_A_PPORT_SOCKET;
  dmaCfg.consSckId = CY_FX_CONSUMER_A_USB_SOCKET;
  dmaCfg.cb = 0; // CyFxSlFifoPtoUDmaCallback;
  apiRetStatus = CyU3PDmaChannelCreate(
      &glChHandleProducerFifoA, CY_U3P_DMA_TYPE_AUTO /*CY_U3P_DMA_TYPE_MANUAL*/,
      &dmaCfg);
  if (apiRetStatus != CY_U3P_SUCCESS) {
    CyU3PDebugPrint(4, "CyU3PDmaChannelCreate failed, Error code = %d\n",
                    apiRetStatus);
    CyFxAppErrorHandler(apiRetStatus);
  }
  // B
  dmaCfg.prodSckId = CY_FX_PRODUCER_B_PPORT_SOCKET;
  dmaCfg.consSckId = CY_FX_CONSUMER_B_USB_SOCKET;
  dmaCfg.cb = 0; // CyFxSlFifoPtoUDmaCallback;
  apiRetStatus = CyU3PDmaChannelCreate(
      &glChHandleProducerFifoB, CY_U3P_DMA_TYPE_AUTO /*CY_U3P_DMA_TYPE_MANUAL*/,
      &dmaCfg);
  if (apiRetStatus != CY_U3P_SUCCESS) {
    CyU3PDebugPrint(4, "CyU3PDmaChannelCreate failed, Error code = %d\n",
                    apiRetStatus);
    CyFxAppErrorHandler(apiRetStatus);
  }
  // C
  dmaCfg.prodSckId = CY_FX_PRODUCER_C_PPORT_SOCKET;
  dmaCfg.consSckId = CY_FX_CONSUMER_C_USB_SOCKET;
  dmaCfg.cb = 0; // CyFxSlFifoPtoUDmaCallback;
  apiRetStatus = CyU3PDmaChannelCreate(
      &glChHandleProducerFifoC, CY_U3P_DMA_TYPE_AUTO /*CY_U3P_DMA_TYPE_MANUAL*/,
      &dmaCfg);
  if (apiRetStatus != CY_U3P_SUCCESS) {
    CyU3PDebugPrint(4, "CyU3PDmaChannelCreate failed, Error code = %d\n",
                    apiRetStatus);
    CyFxAppErrorHandler(apiRetStatus);
  }

  /* Flush the Endpoint memory */
  CyU3PUsbFlushEp(CY_FX_EP_PRODUCER);
  CyU3PUsbFlushEp(CY_FX_EP_CONSUMER_A);
  CyU3PUsbFlushEp(CY_FX_EP_CONSUMER_B);
  CyU3PUsbFlushEp(CY_FX_EP_CONSUMER_C);

  /* Set DMA channel transfer size. */
  apiRetStatus =
      CyU3PDmaChannelSetXfer(&glChHandleConsumerFifo, CY_FX_SLFIFO_DMA_TX_SIZE);
  if (apiRetStatus != CY_U3P_SUCCESS) {
    CyFxAppErrorHandler(apiRetStatus);
  }
  apiRetStatus = CyU3PDmaChannelSetXfer(&glChHandleProducerFifoA,
                                        CY_FX_SLFIFO_DMA_RX_SIZE);
  if (apiRetStatus != CY_U3P_SUCCESS) {
    CyFxAppErrorHandler(apiRetStatus);
  }
  apiRetStatus = CyU3PDmaChannelSetXfer(&glChHandleProducerFifoB,
                                        CY_FX_SLFIFO_DMA_RX_SIZE);
  if (apiRetStatus != CY_U3P_SUCCESS) {
    CyFxAppErrorHandler(apiRetStatus);
  }
  apiRetStatus = CyU3PDmaChannelSetXfer(&glChHandleProducerFifoC,
                                        CY_FX_SLFIFO_DMA_RX_SIZE);
  if (apiRetStatus != CY_U3P_SUCCESS) {
    CyFxAppErrorHandler(apiRetStatus);
  }

  /* Update the status flag. */
  glIsApplnActive = CyTrue;
}

/* This function stops the slave FIFO loop application. This shall be called
 * whenever a RESET or DISCONNECT event is received from the USB host. The
 * endpoints are disabled and the DMA pipe is destroyed by this function. */
void CyFxSlFifoApplnStop(void) {
  CyU3PEpConfig_t epCfg;
  CyU3PReturnStatus_t apiRetStatus = CY_U3P_SUCCESS;

  /* Flush the endpoint memory */
  CyU3PUsbFlushEp(CY_FX_EP_PRODUCER);
  CyU3PUsbFlushEp(CY_FX_EP_CONSUMER_A);
  CyU3PUsbFlushEp(CY_FX_EP_CONSUMER_B);
  CyU3PUsbFlushEp(CY_FX_EP_CONSUMER_C);

  /* Destroy the channel */
  CyU3PDmaChannelDestroy(&glChHandleConsumerFifo);
  CyU3PDmaChannelDestroy(&glChHandleProducerFifoA);
  CyU3PDmaChannelDestroy(&glChHandleProducerFifoB);
  CyU3PDmaChannelDestroy(&glChHandleProducerFifoC);

  /* Disable endpoints. */
  CyU3PMemSet((uint8_t *)&epCfg, 0, sizeof(epCfg));
  epCfg.enable = CyFalse;

  /* Producer endpoint configuration. */
  apiRetStatus = CyU3PSetEpConfig(CY_FX_EP_PRODUCER, &epCfg);
  if (apiRetStatus != CY_U3P_SUCCESS) {
    CyFxAppErrorHandler(apiRetStatus);
  }

  /* Consumer endpoint configuration. */
  // A
  apiRetStatus = CyU3PSetEpConfig(CY_FX_EP_CONSUMER_A, &epCfg);
  if (apiRetStatus != CY_U3P_SUCCESS) {
    CyFxAppErrorHandler(apiRetStatus);
  }
  // B
  apiRetStatus = CyU3PSetEpConfig(CY_FX_EP_CONSUMER_B, &epCfg);
  if (apiRetStatus != CY_U3P_SUCCESS) {
    CyFxAppErrorHandler(apiRetStatus);
  }
  // C
  apiRetStatus = CyU3PSetEpConfig(CY_FX_EP_CONSUMER_C, &epCfg);
  if (apiRetStatus != CY_U3P_SUCCESS) {
    CyFxAppErrorHandler(apiRetStatus);
  }
}

void CyFxApplnStart(void) {

  CyU3PUSBSpeed_t usbSpeed = CyU3PUsbGetSpeed();
  uint16_t size = 0;

  /* First identify the usb speed. Once that is identified,
   * create a DMA channel and start the transfer on this. */

  /* Based on the Bus Speed configure the endpoint packet size */
  switch (usbSpeed) {
  case CY_U3P_FULL_SPEED:
    size = 64;
    break;

  case CY_U3P_HIGH_SPEED:
    size = 512;
    break;

  case CY_U3P_SUPER_SPEED:
    CyU3PUsbLPMDisable();
    size = 1024;
    break;

  default:
    // CyU3PDebugPrint (4, "Error! Invalid USB speed.\n");
    CyFxAppErrorHandler(CY_U3P_ERROR_FAILURE);
    break;
  }

  CyFxSlFifoApplnStart(size);
  CyFxUSBUARTAppStart(size);

  glIsApplnActive = CyTrue;
}

void CyFxApplnStop(void) {
  CyU3PUsbLPMEnable();
  glIsApplnActive = CyFalse;

  CyFxUSBUARTAppStop();
  CyFxSlFifoApplnStop();
}

/* Callback to handle the USB setup requests. */
CyBool_t CyFxApplnUSBSetupCB(uint32_t setupdat0, uint32_t setupdat1) {
  /* Fast enumeration is used. Only requests addressed to the interface, class,
   * vendor and unknown control requests are received by this function.
   * This application does not support any class or vendor requests. */
  uint16_t readCount = 0;
  uint8_t bRequest, bReqType;
  uint8_t bType, bTarget;
  uint16_t wValue, wIndex;
  CyBool_t isHandled = CyFalse;
  uint8_t config_data[7];
  CyU3PReturnStatus_t status = CY_U3P_SUCCESS;
  CyU3PReturnStatus_t apiRetStatus = CY_U3P_SUCCESS;
  CyU3PUartConfig_t uartConfig;

  /* Decode the fields from the setup request. */
  bReqType = (setupdat0 & CY_U3P_USB_REQUEST_TYPE_MASK);
  bType = (bReqType & CY_U3P_USB_TYPE_MASK);
  bTarget = (bReqType & CY_U3P_USB_TARGET_MASK);
  bRequest = ((setupdat0 & CY_U3P_USB_REQUEST_MASK) >> CY_U3P_USB_REQUEST_POS);
  wValue = ((setupdat0 & CY_U3P_USB_VALUE_MASK) >> CY_U3P_USB_VALUE_POS);
  wIndex = ((setupdat1 & CY_U3P_USB_INDEX_MASK) >> CY_U3P_USB_INDEX_POS);

  if (bType == CY_U3P_USB_STANDARD_RQT) {
    /* Handle SET_FEATURE(FUNCTION_SUSPEND) and CLEAR_FEATURE(FUNCTION_SUSPEND)
     * requests here. It should be allowed to pass if the device is in
     * configured
     * state and failed otherwise. */
    if ((bTarget == CY_U3P_USB_TARGET_INTF) &&
        ((bRequest == CY_U3P_USB_SC_SET_FEATURE) ||
         (bRequest == CY_U3P_USB_SC_CLEAR_FEATURE)) &&
        (wValue == 0)) {
      if (glIsApplnActive)
        CyU3PUsbAckSetup();
      else
        CyU3PUsbStall(0, CyTrue, CyFalse);

      isHandled = CyTrue;
    }

    /* CLEAR_FEATURE request for endpoint is always passed to the
     * setup callback regardless of the enumeration model used. When a
     * clear feature is received, the previous transfer has to be
     * flushed and cleaned up. This is done at the protocol
     * level. Since this is just a loopback operation, there is no
     * higher level protocol. So flush the EP memory and reset the DMA
     * channel associated with it. If there are more than one EP
     * associated with the channel reset both the EPs. The endpoint
     * stall and toggle / sequence number is also expected to be
     * reset. Return CyFalse to make the library clear the stall and
     * reset the endpoint toggle. Or invoke the CyU3PUsbStall (ep,
     * CyFalse, CyTrue) and return CyTrue.  Here we are clearing the
     * stall. */
    if ((bTarget == CY_U3P_USB_TARGET_ENDPT) &&
        (bRequest == CY_U3P_USB_SC_CLEAR_FEATURE) &&
        (wValue == CY_U3P_USBX_FS_EP_HALT)) {
      if (glIsApplnActive) {
        if (wIndex == CY_FX_EP_PRODUCER) {
          CyU3PDmaChannelReset(&glChHandleConsumerFifo);
          CyU3PUsbFlushEp(CY_FX_EP_PRODUCER);
          CyU3PUsbResetEp(CY_FX_EP_PRODUCER);
          CyU3PDmaChannelSetXfer(&glChHandleConsumerFifo,
                                 CY_FX_SLFIFO_DMA_TX_SIZE);
        }

        if (wIndex == CY_FX_EP_CONSUMER_A) {
          CyU3PDmaChannelReset(&glChHandleProducerFifoA);
          CyU3PUsbFlushEp(CY_FX_EP_CONSUMER_A);
          CyU3PUsbResetEp(CY_FX_EP_CONSUMER_A);
          CyU3PDmaChannelSetXfer(&glChHandleProducerFifoA,
                                 CY_FX_SLFIFO_DMA_RX_SIZE);
        }

        if (wIndex == CY_FX_EP_CONSUMER_B) {
          CyU3PDmaChannelReset(&glChHandleProducerFifoB);
          CyU3PUsbFlushEp(CY_FX_EP_CONSUMER_B);
          CyU3PUsbResetEp(CY_FX_EP_CONSUMER_B);
          CyU3PDmaChannelSetXfer(&glChHandleProducerFifoB,
                                 CY_FX_SLFIFO_DMA_RX_SIZE);
        }

        if (wIndex == CY_FX_EP_CONSUMER_C) {
          CyU3PDmaChannelReset(&glChHandleProducerFifoC);
          CyU3PUsbFlushEp(CY_FX_EP_CONSUMER_C);
          CyU3PUsbResetEp(CY_FX_EP_CONSUMER_C);
          CyU3PDmaChannelSetXfer(&glChHandleProducerFifoC,
                                 CY_FX_SLFIFO_DMA_RX_SIZE);
        }

        CyU3PUsbStall(wIndex, CyFalse, CyTrue);

        CyU3PUsbAckSetup();
        isHandled = CyTrue;
      }
    }

  }
  /* Check for CDC Class Requests */
  else if (bType == CY_U3P_USB_CLASS_RQT) {

    /* CDC Specific Requests */
    /* set_line_coding */
    if (bRequest == SET_LINE_CODING) {
      status = CyU3PUsbGetEP0Data(0x07, config_data, &readCount);
      if (status != CY_U3P_SUCCESS) {
        CyFxAppErrorHandler(status);
      }
      if (readCount != 0x07) {
        CyFxAppErrorHandler(CY_U3P_ERROR_BAD_SIZE);
      } else {
        CyU3PMemSet((uint8_t *)&uartConfig, 0, sizeof(uartConfig));
        uartConfig.baudRate = (CyU3PUartBaudrate_t)(
            config_data[0] | (config_data[1] << 8) | (config_data[2] << 16) |
            (config_data[3] << 24));
        if (config_data[4] == 0) {
          uartConfig.stopBit = CY_U3P_UART_ONE_STOP_BIT;
        } else if (config_data[4] == 2) {
          uartConfig.stopBit = CY_U3P_UART_TWO_STOP_BIT;
        } else {
          /* Give invalid value. */
          uartConfig.stopBit = (CyU3PUartStopBit_t)0;
        }
        if (config_data[5] == 1) {
          uartConfig.parity = CY_U3P_UART_ODD_PARITY;
        } else if (config_data[5] == 2) {
          uartConfig.parity = CY_U3P_UART_EVEN_PARITY;
        } else {
          /* 0 = no parity; any other value - invalid parity. */
          uartConfig.parity = CY_U3P_UART_NO_PARITY;
        }

        uartConfig.txEnable = CyTrue;
        uartConfig.rxEnable = CyTrue;
        uartConfig.flowCtrl = CyFalse;
        uartConfig.isDma = CyTrue;

        /* Set the uart configuration */
        apiRetStatus = CyU3PUartSetConfig(&uartConfig, NULL);
        if (apiRetStatus == CY_U3P_SUCCESS) {
          CyU3PMemCopy((uint8_t *)&glUartConfig, (uint8_t *)&uartConfig,
                       sizeof(CyU3PUartConfig_t));
        }
      }
    }
    /* get_line_coding */
    else if (bRequest == GET_LINE_CODING) {
      /* get current uart config */
      config_data[0] = glUartConfig.baudRate & (0x000000FF);
      config_data[1] = ((glUartConfig.baudRate & (0x0000FF00)) >> 8);
      config_data[2] = ((glUartConfig.baudRate & (0x00FF0000)) >> 16);
      config_data[3] = ((glUartConfig.baudRate & (0xFF000000)) >> 24);
      if (glUartConfig.stopBit == CY_U3P_UART_ONE_STOP_BIT) {
        config_data[4] = 0;
      } else /* CY_U3P_UART_TWO_STOP_BIT */
      {
        config_data[4] = 2;
      }

      if (glUartConfig.parity == CY_U3P_UART_EVEN_PARITY) {
        config_data[5] = 2;
      } else if (glUartConfig.parity == CY_U3P_UART_ODD_PARITY) {
        config_data[5] = 1;
      } else {
        config_data[5] = 0;
      }
      config_data[6] = 0x08;
      status = CyU3PUsbSendEP0Data(0x07, config_data);
      if (status != CY_U3P_SUCCESS) {
        CyFxAppErrorHandler(status);
      }
    }
    /* SET_CONTROL_LINE_STATE */
    else if (bRequest == SET_CONTROL_LINE_STATE) {
      if (glIsApplnActive) {
        CyU3PUsbAckSetup();
      } else
        CyU3PUsbStall(0, CyTrue, CyFalse);
    } else {
      status = CY_U3P_ERROR_FAILURE;
    }
  }

  return isHandled;
}

/* This is the callback function to handle the USB events. */
void CyFxApplnUSBEventCB(CyU3PUsbEventType_t evtype, uint16_t evdata) {
  switch (evtype) {
  case CY_U3P_USB_EVENT_SETCONF:
    /* Stop the application before re-starting. */
    if (glIsApplnActive) {
      CyFxApplnStop();
    }
    /* Start the loop back function. */
    CyFxApplnStart();
    break;

  case CY_U3P_USB_EVENT_RESET:
  case CY_U3P_USB_EVENT_DISCONNECT:
    /* Stop the loop back function. */
    if (glIsApplnActive) {
      CyFxApplnStop();
    }
    break;

  default:
    break;
  }
}

/* Callback function to handle LPM requests from the USB 3.0 host. This function
   is invoked by the API
   whenever a state change from U0 -> U1 or U0 -> U2 happens. If we return
   CyTrue from this function, the
   FX3 device is retained in the low power state. If we return CyFalse, the FX3
   device immediately tries
   to trigger an exit back to U0.

   This application does not have any state in which we should not allow U1/U2
   transitions; and therefore
   the function always return CyTrue.
 */
CyBool_t CyFxApplnLPMRqtCB(CyU3PUsbLinkPowerMode link_mode) { return CyTrue; }

/* This function initializes the GPIF interface and initializes
 * the USB interface. */
void CyFxApplnInit(void) {
  CyU3PPibClock_t pibClock;
  CyU3PReturnStatus_t apiRetStatus = CY_U3P_SUCCESS;

  /* Initialize the p-port block. */
  pibClock.clkDiv = 2;
  pibClock.clkSrc = CY_U3P_SYS_CLK;
  pibClock.isHalfDiv = CyFalse;
  /* Disable DLL for sync GPIF */
  pibClock.isDllEnable = CyFalse;
  apiRetStatus = CyU3PPibInit(CyTrue, &pibClock);
  if (apiRetStatus != CY_U3P_SUCCESS) {
    CyFxAppErrorHandler(apiRetStatus);
  }

  // SET DRIVE STRENGTH
  apiRetStatus = CyU3PSetPportDriveStrength(CY_U3P_DS_QUARTER_STRENGTH);
  if (apiRetStatus != CY_U3P_SUCCESS) {
                                CyFxAppErrorHandler(apiRetStatus);
  }

  /* Load the GPIF configuration for Slave FIFO sync mode. */
  apiRetStatus = CyU3PGpifLoad(&CyFxGpifConfig);
  if (apiRetStatus != CY_U3P_SUCCESS) {
    CyU3PDebugPrint(4, "CyU3PGpifLoad failed, Error Code = %d\n", apiRetStatus);
    CyFxAppErrorHandler(apiRetStatus);
  }

  /* Start the state machine. */
  apiRetStatus = CyU3PGpifSMStart(RESET, ALPHA_RESET);
  if (apiRetStatus != CY_U3P_SUCCESS) {
    CyU3PDebugPrint(4, "CyU3PGpifSMStart failed, Error Code = %d\n",
                    apiRetStatus);
    CyFxAppErrorHandler(apiRetStatus);
  }

  /* Start the USB functionality. */
  apiRetStatus = CyU3PUsbStart();
  if (apiRetStatus != CY_U3P_SUCCESS) {
    CyFxAppErrorHandler(apiRetStatus);
  }

  /* Initialize the UART module */
  apiRetStatus = CyU3PUartInit();
  if (apiRetStatus != CY_U3P_SUCCESS) {
    /* Error handling */
    CyFxAppErrorHandler(apiRetStatus);
  }

  /* Configure the UART */
  CyU3PMemSet((uint8_t *)&glUartConfig, 0, sizeof(glUartConfig));
  glUartConfig.baudRate = CY_U3P_UART_BAUDRATE_115200;
  glUartConfig.stopBit = CY_U3P_UART_ONE_STOP_BIT;
  glUartConfig.parity = CY_U3P_UART_NO_PARITY;
  glUartConfig.flowCtrl = CyFalse;
  glUartConfig.txEnable = CyTrue;
  glUartConfig.rxEnable = CyTrue;
  glUartConfig.isDma = CyTrue;

  /* Set the UART configuration */
  apiRetStatus = CyU3PUartSetConfig(&glUartConfig, NULL);
  if (apiRetStatus != CY_U3P_SUCCESS) {
    /* Error handling */
    CyFxAppErrorHandler(apiRetStatus);
  }

  /* The fast enumeration is the easiest way to setup a USB connection,
   * where all enumeration phase is handled by the library. Only the
   * class / vendor requests need to be handled by the application. */
  CyU3PUsbRegisterSetupCallback(CyFxApplnUSBSetupCB, CyTrue);

  /* Setup the callback to handle the USB events. */
  CyU3PUsbRegisterEventCallback(CyFxApplnUSBEventCB);

  /* Register a callback to handle LPM requests from the USB 3.0 host. */
  CyU3PUsbRegisterLPMRequestCallback(CyFxApplnLPMRqtCB);

  /* Set the USB Enumeration descriptors */

  /* Super speed device descriptor. */
  apiRetStatus = CyU3PUsbSetDesc(CY_U3P_USB_SET_SS_DEVICE_DESCR, 0,
                                 (uint8_t *)CyFxUSB30DeviceDscr);
  if (apiRetStatus != CY_U3P_SUCCESS) {
    // CyU3PDebugPrint (4, "USB set device descriptor failed, Error code =
    // %d\n", apiRetStatus);
    CyFxAppErrorHandler(apiRetStatus);
  }

  /* High speed device descriptor. */
  apiRetStatus = CyU3PUsbSetDesc(CY_U3P_USB_SET_HS_DEVICE_DESCR, 0,
                                 (uint8_t *)CyFxUSB20DeviceDscr);
  if (apiRetStatus != CY_U3P_SUCCESS) {
    // CyU3PDebugPrint (4, "USB set device descriptor failed, Error code =
    // %d\n", apiRetStatus);
    CyFxAppErrorHandler(apiRetStatus);
  }

  /* BOS descriptor */
  apiRetStatus = CyU3PUsbSetDesc(CY_U3P_USB_SET_SS_BOS_DESCR, 0,
                                 (uint8_t *)CyFxUSBBOSDscr);
  if (apiRetStatus != CY_U3P_SUCCESS) {
    // CyU3PDebugPrint (4, "USB set configuration descriptor failed, Error code
    // = %d\n", apiRetStatus);
    CyFxAppErrorHandler(apiRetStatus);
  }

  /* Device qualifier descriptor */
  apiRetStatus = CyU3PUsbSetDesc(CY_U3P_USB_SET_DEVQUAL_DESCR, 0,
                                 (uint8_t *)CyFxUSBDeviceQualDscr);
  if (apiRetStatus != CY_U3P_SUCCESS) {
    // CyU3PDebugPrint (4, "USB set device qualifier descriptor failed, Error
    // code = %d\n", apiRetStatus);
    CyFxAppErrorHandler(apiRetStatus);
  }

  /* Super speed configuration descriptor */
  apiRetStatus = CyU3PUsbSetDesc(CY_U3P_USB_SET_SS_CONFIG_DESCR, 0,
                                 (uint8_t *)CyFxUSBSSConfigDscr);
  if (apiRetStatus != CY_U3P_SUCCESS) {
    // CyU3PDebugPrint (4, "USB set configuration descriptor failed, Error code
    // = %d\n", apiRetStatus);
    CyFxAppErrorHandler(apiRetStatus);
  }

  /* High speed configuration descriptor */
  apiRetStatus = CyU3PUsbSetDesc(CY_U3P_USB_SET_HS_CONFIG_DESCR, 0,
                                 (uint8_t *)CyFxUSBHSConfigDscr);
  if (apiRetStatus != CY_U3P_SUCCESS) {
    // CyU3PDebugPrint (4, "USB Set Other Speed Descriptor failed, Error Code =
    // %d\n", apiRetStatus);
    CyFxAppErrorHandler(apiRetStatus);
  }

  /* Full speed configuration descriptor */
  apiRetStatus = CyU3PUsbSetDesc(CY_U3P_USB_SET_FS_CONFIG_DESCR, 0,
                                 (uint8_t *)CyFxUSBFSConfigDscr);
  if (apiRetStatus != CY_U3P_SUCCESS) {
    // CyU3PDebugPrint (4, "USB Set Configuration Descriptor failed, Error Code
    // = %d\n", apiRetStatus);
    CyFxAppErrorHandler(apiRetStatus);
  }

  /* String descriptor 0 */
  apiRetStatus = CyU3PUsbSetDesc(CY_U3P_USB_SET_STRING_DESCR, 0,
                                 (uint8_t *)CyFxUSBStringLangIDDscr);
  if (apiRetStatus != CY_U3P_SUCCESS) {
    // CyU3PDebugPrint (4, "USB set string descriptor failed, Error code =
    // %d\n", apiRetStatus);
    CyFxAppErrorHandler(apiRetStatus);
  }

  /* String descriptor 1 */
  apiRetStatus = CyU3PUsbSetDesc(CY_U3P_USB_SET_STRING_DESCR, 1,
                                 (uint8_t *)CyFxUSBManufactureDscr);
  if (apiRetStatus != CY_U3P_SUCCESS) {
    // CyU3PDebugPrint (4, "USB set string descriptor failed, Error code =
    // %d\n", apiRetStatus);
    CyFxAppErrorHandler(apiRetStatus);
  }

  /* String descriptor 2 */
  apiRetStatus = CyU3PUsbSetDesc(CY_U3P_USB_SET_STRING_DESCR, 2,
                                 (uint8_t *)CyFxUSBProductDscr);
  if (apiRetStatus != CY_U3P_SUCCESS) {
    // CyU3PDebugPrint (4, "USB set string descriptor failed, Error code =
    // %d\n", apiRetStatus);
    CyFxAppErrorHandler(apiRetStatus);
  }

  /* String descriptor 3 */
  apiRetStatus = CyU3PUsbSetDesc(CY_U3P_USB_SET_STRING_DESCR, 3,
                                 (uint8_t *)CyFxUSBSerialNumDesc);
  if (apiRetStatus != CY_U3P_SUCCESS) {
    // CyU3PDebugPrint (4, "USB set string descriptor failed, Error code =
    // %d\n", apiRetStatus);
    CyFxAppErrorHandler(apiRetStatus);
  }

  /* Connect the USB Pins with super speed operation enabled. */
  apiRetStatus = CyU3PConnectState(CyTrue, CyTrue);
  if (apiRetStatus != CY_U3P_SUCCESS) {
    // CyU3PDebugPrint (4, "USB Connect failed, Error code = %d\n",
    // apiRetStatus);
    CyFxAppErrorHandler(apiRetStatus);
  }
}

/* Entry function for the USBUARTAppThread */
void USBAppThread_Entry(uint32_t input) {
  /* Initialize the USBUART Example Application */
  CyFxApplnInit();

  for (;;) {
    if (glIsApplnActive) {
      /* While the application is active, check for data sent during the last 50
         ms. If no data
         has been sent to the host, use the channel wrap-up feature to send any
         partial buffer to
         the USB host.
       */
      if (glPktsPending == 0) {
        CyU3PDmaChannelSetWrapUp(&glChHandleUarttoUsb);
      }
      glPktsPending = 0;
    }

    CyU3PThreadSleep(50);
  }
}

/* Application define function which creates the threads. */
void CyFxApplicationDefine(void) {
  void *ptr = NULL;
  uint32_t retThrdCreate = CY_U3P_SUCCESS;

  /* Allocate the memory for the thread */
  ptr = CyU3PMemAlloc(CY_FX_USBUART_THREAD_STACK + CY_FX_SLFIFO_THREAD_STACK);

  /*create uart thread */
  retThrdCreate = CyU3PThreadCreate(
      &USBAppThread,      /* USBUART Example App Thread structure */
      "21:USBUART_FIFO",  /* Thread ID and Thread name */
      USBAppThread_Entry, /* USBUART Example App Thread Entry function */
      0,                  /* No input parameter to thread */
      ptr,                /* Pointer to the allocated thread stack */
      CY_FX_USBUART_THREAD_STACK +
          CY_FX_SLFIFO_THREAD_STACK, /* USBUART Example App Thread stack size */
      CY_FX_USBUART_THREAD_PRIORITY, /* USBUART Example App Thread priority */
      CY_FX_USBUART_THREAD_PRIORITY, /* USBUART Example App Thread priority */
      CYU3P_NO_TIME_SLICE, /* No time slice for the application thread */
      CYU3P_AUTO_START     /* Start the Thread immediately */
      );

  /* Check the return code */
  if (retThrdCreate != 0) {
    /* Thread Creation failed with the error code retThrdCreate */

    /* Add custom recovery or debug actions here */

    /* Application cannot continue */
    /* Loop indefinitely */
    while (1)
      ;
  }
}

/*
 * Main function
 */
int main(void) {
  CyU3PIoMatrixConfig_t io_cfg;
  CyU3PReturnStatus_t status = CY_U3P_SUCCESS;
  CyU3PSysClockConfig_t clockConfig;

/* When the GPIF data bus is configured as 32-bits wide and running at 100 MHz
   (synchronous),
   the FX3 system clock has to be set to a frequency greater than 400 MHz. */
  clockConfig.setSysClk400 = CyTrue;

  clockConfig.cpuClkDiv = 2;
  clockConfig.dmaClkDiv = 2;
  clockConfig.mmioClkDiv = 2;
  clockConfig.useStandbyClk = CyFalse;
  clockConfig.clkSrc = CY_U3P_SYS_CLK;
  status = CyU3PDeviceInit(&clockConfig);
  if (status != CY_U3P_SUCCESS) {
    goto handle_fatal_error;
  }

  /* Initialize the caches. Enable both Instruction and Data Caches. */
  status = CyU3PDeviceCacheControl(CyTrue, CyTrue, CyTrue);
  if (status != CY_U3P_SUCCESS) {
    goto handle_fatal_error;
  }

  /* Configure the IO matrix for the device. On the FX3 DVK board, the COM port
   * is connected to the IO(53:56). This means that either DQ32 mode should be
   * selected or lppMode should be set to UART_ONLY. Here we are choosing
   * UART_ONLY configuration for 16 bit slave FIFO configuration and setting
   * isDQ32Bit for 32-bit slave FIFO configuration. */
  io_cfg.s0Mode = CY_U3P_SPORT_INACTIVE;
  io_cfg.s1Mode = CY_U3P_SPORT_INACTIVE;
  io_cfg.useUart = CyTrue;
  io_cfg.useI2C = CyFalse;
  io_cfg.useI2S = CyFalse;
  io_cfg.useSpi = CyFalse;
  io_cfg.isDQ32Bit = CyTrue;
  io_cfg.lppMode = CY_U3P_IO_MATRIX_LPP_DEFAULT;

  /* No GPIOs are enabled. */
  io_cfg.gpioSimpleEn[0] = 0;
  io_cfg.gpioSimpleEn[1] = 0;
  io_cfg.gpioComplexEn[0] = 0;
  io_cfg.gpioComplexEn[1] = 0;
  status = CyU3PDeviceConfigureIOMatrix(&io_cfg);
  if (status != CY_U3P_SUCCESS) {
    goto handle_fatal_error;
  }

  /* This is a non returnable call for initializing the RTOS kernel */
  CyU3PKernelEntry();

  /* Dummy return to make the compiler happy */
  return 0;

handle_fatal_error:

  /* Cannot recover from this error. */
  while (1)
    ;
}

/* [ ] */
