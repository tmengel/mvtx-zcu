/*
 ## Cypress USB 3.0 Platform header file (cyfxslfifosync.h)
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

/* This file contains the constants and definitions used by the Slave FIFO application example */

#ifndef _INCLUDED_CYFXSLFIFOASYNC_H_
#define _INCLUDED_CYFXSLFIFOASYNC_H_

#include "cyu3externcstart.h"
#include "cyu3types.h"
#include "cyu3usbconst.h"

/* Custom serial number; Final serial number in the form
   00000-{FX3_SERIAL_NUMBER_0 .. FX3_SERIAL_NUMBER_5}
*/

#define FX3_SERIAL_NUMBER_0 '0'
#define FX3_SERIAL_NUMBER_1 '0'
#define FX3_SERIAL_NUMBER_2 '0'
#define FX3_SERIAL_NUMBER_3 '0'
#define FX3_SERIAL_NUMBER_4 '0'
#define FX3_SERIAL_NUMBER_5 '0'

/* 16/32 bit GPIF Configuration select */
/* Set CY_FX_SLFIFO_GPIF_16_32BIT_CONF_SELECT = 0 for 16 bit GPIF data bus.
 * Set CY_FX_SLFIFO_GPIF_16_32BIT_CONF_SELECT = 1 for 32 bit GPIF data bus.
 */
//#define CY_FX_SLFIFO_GPIF_16_32BIT_CONF_SELECT (0)

#define CY_FX_SLFIFO_DMA_BUF_COUNT      (2)                       /* Slave FIFO channel buffer count */
#define CY_FX_SLFIFO_DMA_TX_SIZE        (0)	                  /* DMA transfer size is set to infinite */
#define CY_FX_SLFIFO_DMA_RX_SIZE        (0)	                  /* DMA transfer size is set to infinite */
#define CY_FX_SLFIFO_THREAD_STACK       (0x0400)                  /* Slave FIFO application thread stack size */
#define CY_FX_SLFIFO_THREAD_PRIORITY    (8)                       /* Slave FIFO application thread priority */

/* Endpoint and socket definitions for the Slave FIFO application */

/* To change the Producer and Consumer EP enter the appropriate EP numbers for the #defines.
 * In the case of IN endpoints enter EP number along with the direction bit.
 * For eg. EP 6 IN endpoint is 0x86
 *     and EP 6 OUT endpoint is 0x06.
 * To change sockets mention the appropriate socket number in the #defines. */

/* Note: For USB 2.0 the endpoints and corresponding sockets are one-to-one mapped
         i.e. EP 1 is mapped to UIB socket 1 and EP 2 to socket 2 so on */

// Nota: OUT = da USB HOST a FX3, IN = da FX3 a USB HOST
#define CY_FX_EP_PRODUCER               0x03    /* EP 1 OUT */
#define CY_FX_EP_CONSUMER_A             0x83    /* EP 1 IN */
#define CY_FX_EP_CONSUMER_B             0x84    /* EP 2 IN */
#define CY_FX_EP_CONSUMER_C             0x85    /* EP 3 IN */

#define CY_FX_EP_UARTOUT                0x02
#define CY_FX_EP_UARTIN                 0x82
#define CY_FX_EP_INTERRUPT              0x81    /* EP 2 INTR */


#define CY_FX_PRODUCER_USB_SOCKET    CY_U3P_UIB_SOCKET_PROD_3    /* USB Socket 1 is producer */
#define CY_FX_CONSUMER_A_USB_SOCKET  CY_U3P_UIB_SOCKET_CONS_3    /* USB Socket 1 is consumer */
#define CY_FX_CONSUMER_B_USB_SOCKET  CY_U3P_UIB_SOCKET_CONS_4    /* USB Socket 2 is consumer */
#define CY_FX_CONSUMER_C_USB_SOCKET  CY_U3P_UIB_SOCKET_CONS_5    /* USB Socket 3 is consumer */


/* Endpoint and socket definitions for the USB-UART application */
#define CY_FX_EP_PRODUCER1_SOCKET        CY_U3P_UIB_SOCKET_PROD_2
#define CY_FX_EP_CONSUMER1_SOCKET        CY_U3P_LPP_SOCKET_UART_CONS
#define CY_FX_EP_PRODUCER2_SOCKET        CY_U3P_LPP_SOCKET_UART_PROD
#define CY_FX_EP_CONSUMER2_SOCKET        CY_U3P_UIB_SOCKET_CONS_2
#define CY_FX_EP_INTR_CONSUMER1_SOCKET   CY_U3P_UIB_SOCKET_CONS_1

/* Used with FX3 Silicon. */
#define CY_FX_CONSUMER_PPORT_SOCKET    CY_U3P_PIB_SOCKET_0    /* P-port Socket 0 is consumer */
#define CY_FX_PRODUCER_A_PPORT_SOCKET  CY_U3P_PIB_SOCKET_1    /* P-port Socket 1 is producer */
#define CY_FX_PRODUCER_B_PPORT_SOCKET  CY_U3P_PIB_SOCKET_2    /* P-port Socket 2 is producer */
#define CY_FX_PRODUCER_C_PPORT_SOCKET  CY_U3P_PIB_SOCKET_3    /* P-port Socket 3 is producer */

/* Extern definitions for the USB Descriptors */
extern const uint8_t CyFxUSB20DeviceDscr[];
extern const uint8_t CyFxUSB30DeviceDscr[];
extern const uint8_t CyFxUSBDeviceQualDscr[];
extern const uint8_t CyFxUSBFSConfigDscr[];
extern const uint8_t CyFxUSBHSConfigDscr[];
extern const uint8_t CyFxUSBBOSDscr[];
extern const uint8_t CyFxUSBSSConfigDscr[];
extern const uint8_t CyFxUSBStringLangIDDscr[];
extern const uint8_t CyFxUSBManufactureDscr[];
extern const uint8_t CyFxUSBProductDscr[];
extern const uint8_t CyFxUSBSerialNumDesc[];

/* Uart configuration */
#define  CY_FX_USBUART_DMA_BUF_COUNT      (3)
#define  CY_FX_USBUART_THREAD_STACK       (1000)
#define  CY_FX_USBUART_THREAD_PRIORITY     (8)


/* Descriptor Types */
#define CY_FX_BOS_DSCR_TYPE             15
#define CY_FX_DEVICE_CAPB_DSCR_TYPE     16
#define CY_FX_SS_EP_COMPN_DSCR_TYPE     48

/* Device Capability Type Codes */
#define CY_FX_WIRELESS_USB_CAPB_TYPE    1
#define CY_FX_USB2_EXTN_CAPB_TYPE       2
#define CY_FX_SS_USB_CAPB_TYPE          3
#define CY_FX_CONTAINER_ID_CAPBD_TYPE   4


#include "cyu3externcend.h"

#endif /* _INCLUDED_CYFXSLFIFOASYNC_H_ */

/*[]*/
