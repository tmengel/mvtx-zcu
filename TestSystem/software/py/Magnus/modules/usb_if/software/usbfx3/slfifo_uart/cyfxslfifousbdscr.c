/*
 ## Cypress USB 3.0 Platform header file (cyfxslfifousbdscr.c)
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

/* This file contains the USB enumeration descriptors for the slave FIFO
 * application example.
 * The descriptor arrays must be 32 byte aligned and multiple of 32 bytes if the
 * D-cache is
 * turned on. If the linker used is not capable of supporting the aligned
 * feature for this,
 * either the descriptors must be placed in a different section and the section
 * should be
 * 32 byte aligned and 32 byte multiple; or dynamically allocated buffer
 * allocated using
 * CyU3PDmaBufferAlloc must be used, and the descriptor must be loaded into it.
 * The example
 * assumes that the aligned attribute for 32 bytes is supported by the linker.
 * Do not add
 * any other variables to this file other than USB descriptors. This is not the
 * only
 * pre-requisite to enabling the D-cache. Refer to the documentation for
 * CyU3PDeviceCacheControl for more information.
 */

#include "cyfxslfifosync.h"

/* Standard device descriptor for USB 3.0 */
const uint8_t CyFxUSB30DeviceDscr[] __attribute__((aligned(32))) = {
  0x12,                           /* Descriptor size */
  CY_U3P_USB_DEVICE_DESCR,       /* Device descriptor type */
  0x00,                    0x03, /* USB 3.0 */
  0x00,                          /* Device class */
  0x00,                          /* Device sub-class */
  0x00,                          /* Device protocol */
  0x09,                          /* Maxpacket size for EP0 : 2^9 */
  0xB4,                    0x04, /* Vendor ID */
  0x08,                    0x00, /* Product ID */
  0x00,                    0x00, /* Device release number */
  0x01,                          /* Manufacture string index */
  0x02,                          /* Product string index */
  0x03,                          /* Serial number string index */
  0x01                           /* Number of configurations */
};

/* Standard device descriptor for USB 2.0 */
const uint8_t CyFxUSB20DeviceDscr[] __attribute__((aligned(32))) = {
  0x12,                          /* Descriptor size */
  CY_U3P_USB_DEVICE_DESCR,       /* Device descriptor type */
  0x10,                    0x02, /* USB 2.10 */
  0x00,                          /* Device class */
  0x00,                          /* Device sub-class */
  0x00,                          /* Device protocol */
  0x40,                          /* Maxpacket size for EP0 : 64 bytes */
  0xB4,                    0x04, /* Vendor ID */
  0x08,                    0x00, /* Product ID */
  0x00,                    0x00, /* Device release number */
  0x01,                          /* Manufacture string index */
  0x02,                          /* Product string index */
  0x03,                          /* Serial number string index */
  0x01                           /* Number of configurations */
};

/* Binary device object store descriptor */
const uint8_t CyFxUSBBOSDscr[] __attribute__((aligned(32))) = {
  0x05,                             /* Descriptor size */
  CY_U3P_BOS_DESCR,                 /* Device descriptor type */
  0x16,                       0x00, /* Length of this descriptor and all sub
                                       descriptors */
  0x02, /* Number of device capability descriptors */

  /* USB 2.0 extension */
  0x07,                       /* Descriptor size */
  CY_U3P_DEVICE_CAPB_DESCR,   /* Device capability type descriptor */
  CY_U3P_USB2_EXTN_CAPB_TYPE, /* USB 2.0 extension capability type */
  0x02,                       0x00, 0x00,
  0x00, /* Supported device level features: LPM support  */

  /* SuperSpeed device capability */
  0x0A,                             /* Descriptor size */
  CY_U3P_DEVICE_CAPB_DESCR,         /* Device capability type descriptor */
  CY_U3P_SS_USB_CAPB_TYPE,          /* SuperSpeed device capability type */
  0x00,                             /* Supported device level features  */
  0x0E,                       0x00, /* Speeds supported by the device : SS, HS
                                       and FS */
  0x03,                            /* Functionality support */
  0x00,                            /* U1 Device Exit latency */
  0x00,                       0x00 /* U2 Device Exit latency */
};

/* Standard device qualifier descriptor */
const uint8_t CyFxUSBDeviceQualDscr[] __attribute__((aligned(32))) = {
  0x0A,                           /* Descriptor size */
  CY_U3P_USB_DEVQUAL_DESCR,       /* Device qualifier descriptor type */
  0x00,                     0x02, /* USB 2.0 */
  0x02,                           /* Device class */
  0x00,                           /* Device sub-class */
  0x00,                           /* Device protocol */
  0x40,                           /* Maxpacket size for EP0 : 64 bytes */
  0x01,                           /* Number of configurations */
  0x00                            /* Reserved */
};

/* Standard super speed configuration descriptor */
const uint8_t CyFxUSBSSConfigDscr[] __attribute__((aligned(32))) = {
  /* Configuration descriptor */
  0x09,                    /* Descriptor size */
  CY_U3P_USB_CONFIG_DESCR, /* Configuration descriptor type */
  154, 0x00, /* Length of this descriptor and all sub descriptors */
  0x03,      /* Number of interfaces */
  0x01,      /* Configuration number */
  0x00,      /* COnfiguration string index */
  0x80,      /* Config characteristics - Bus powered */
  0x32,      /* Max power consumption of device (in 8mA unit) : 400mA */

  /* Interface Association Descriptor */
  0x08, /*  Interface Assoc Descriptor Length      */
  0x0B, /*  DescriptorType: Interface association  */
  0x00, /*  bfirstInterface	                   */
  0x02, /*  binterface count	                   */
  0x02, /*  bFunctionClass                         */
  0x00, /*  bFunctionSubClass                      */
  0x00, /*  bInterfaceProtocol                     */
  0x00, /*  iInterface                             */

  /* Communication Interface descriptor */
  0x09,                    /* Descriptor size */
  CY_U3P_USB_INTRFC_DESCR, /* Interface Descriptor type */
  0x00,                    /* Interface number */
  0x00,                    /* Alternate setting number */
  0x01,                    /* Number of endpoints */
  0x02,                    /* Interface class : Communication interface */
  0x02,                    /* Interface sub class */
  0x01,                    /* Interface protocol code */
  0x00,                    /* Interface descriptor string index */

  /* CDC Class-specific Descriptors */
  /* Header functional Descriptor */
  0x05,       /* Descriptors length(5) */
  0x24,       /* Descriptor type : CS_Interface */
  0x00,       /* DescriptorSubType : Header Functional Descriptor */
  0x10, 0x01, /* bcdCDC : CDC Release Number */

  /* Abstract Control Management Functional Descriptor */
  0x04, /* Descriptors Length (4) */
  0x24, /* bDescriptorType: CS_INTERFACE */
  0x02, /* bDescriptorSubType: Abstract Control Model Functional Descriptor */
  0x02, /* bmCapabilities: Supports the request combination of Set_Line_Coding,
           Set_Control_Line_State, Get_Line_Coding and the notification
           Serial_State */

  /* Union Functional Descriptor */
  0x05, /* Descriptors Length (5) */
  0x24, /* bDescriptorType: CS_INTERFACE */
  0x06, /* bDescriptorSubType: Union Functional Descriptor */
  0x00, /* bMasterInterface */
  0x01, /* bSlaveInterface */

  /* Call Management Functional Descriptor */
  0x05, /*  Descriptors Length (5) */
  0x24, /*  bDescriptorType: CS_INTERFACE */
  0x01, /*  bDescriptorSubType: Call Management Functional Descriptor */
  0x00, /*  bmCapabilities: Device sends/receives call management information
            only over the Communication Class Interface. */
  0x01, /*  Interface Number of Data Class interface */

  /* Endpoint Descriptor(Interrupt) */
  0x07,                    /* Descriptor size */
  CY_U3P_USB_ENDPNT_DESCR, /* Endpoint descriptor type */
  CY_FX_EP_INTERRUPT,      /* Endpoint address and description */
  CY_U3P_USB_EP_INTR,      /* Interrupt endpoint type */
  0x40,
  0x00, /* Max packet size = 1024 bytes */
  0x01, /* Servicing interval for data transfers */

  /* Super speed endpoint companion descriptor for interrupt endpoint */
  0x06,                     /* Descriptor size */
  CY_U3P_SS_EP_COMPN_DESCR, /* SS endpoint companion descriptor type */
  0x00,                     /* Max no. of packets in a Burst : 1 */
  0x00,                     /* Mult.: Max number of packets : 1 */
  0x40, 0x00,               /* Bytes per interval : 1024 */

  /* Data Interface Descriptor */
  0x09,                    /* Descriptor size */
  CY_U3P_USB_INTRFC_DESCR, /* Interface Descriptor type */
  0x01,                    /* Interface number */
  0x00,                    /* Alternate setting number */
  0x02,                    /* Number of endpoints */
  0x0A,                    /* Interface class: Data interface */
  0x00,                    /* Interface sub class */
  0x00,                    /* Interface protocol code */
  0x00,                    /* Interface descriptor string index */

  /* Endpoint Descriptor(BULK-PRODUCER) */
  0x07,                    /* Descriptor size */
  CY_U3P_USB_ENDPNT_DESCR, /* Endpoint descriptor type */
  CY_FX_EP_UARTOUT,        /* Endpoint address and description */
  CY_U3P_USB_EP_BULK,      /* BULK endpoint type */
  0x00, 0x04,              /* Max packet size = 1024 bytes */
  0x00,                    /* Servicing interval for data transfers */

  /* Super speed endpoint companion descriptor for producer ep */
  0x06,                     /* Descriptor size */
  CY_U3P_SS_EP_COMPN_DESCR, /* SS endpoint companion descriptor type */
  0x00,                     /* Max no. of packets in a burst : 1 */
  0x00,                     /* Mult.: Max number of packets : 1 */
  0x00, 0x00,               /* Bytes per interval : 1024 */

  /* Endpoint Descriptor(BULK- CONSUMER) */
  0x07,                    /* Descriptor size */
  CY_U3P_USB_ENDPNT_DESCR, /* Endpoint descriptor type */
  CY_FX_EP_UARTIN,         /* Endpoint address and description */
  CY_U3P_USB_EP_BULK,      /* BULK endpoint type */
  0x00, 0x04,              /* Max packet size = 1024 bytes */
  0x00,                    /* Servicing interval for data transfers */

  /* Super speed endpoint companion descriptor for consumer ep */
  0x06,                     /* Descriptor size */
  CY_U3P_SS_EP_COMPN_DESCR, /* SS endpoint companion descriptor type */
  0x00,                     /* Max no. of packets in a burst : 1 */
  0x00,                     /* Mult.: Max number of packets : 1 */
  0x00, 0x00,               /* Bytes per interval : 1024 */

  /* Interface descriptor  FIFO*/
  0x09,                    /* Descriptor size */
  CY_U3P_USB_INTRFC_DESCR, /* Interface Descriptor type */
  0x02,                    /* Interface number */
  0x00,                    /* Alternate setting number */
  0x04,                    /* Number of end points */
  0xFF,                    /* Interface class */
  0x00,                    /* Interface sub class */
  0x00,                    /* Interface protocol code */
  0x00,                    /* Interface descriptor string index */

  /* Endpoint descriptor for producer EP */
  0x07,                    /* Descriptor size */
  CY_U3P_USB_ENDPNT_DESCR, /* Endpoint descriptor type */
  CY_FX_EP_PRODUCER,       /* Endpoint address and description */
  CY_U3P_USB_EP_BULK,      /* Bulk endpoint type */
  0x00, 0x04,              /* Max packet size = 1024 bytes */
  0x00, /* Servicing interval for data transfers : 0 for bulk */

  /* Super speed endpoint companion descriptor for producer EP */
  0x06,                     /* Descriptor size */
  CY_U3P_SS_EP_COMPN_DESCR, /* SS endpoint companion descriptor type */
  0x00,       /* Max no. of packets in a burst : 0: burst 1 packet at a time */
  0x00,       /* Max streams for bulk EP = 0 (No streams) */
  0x00, 0x00, /* Service interval for the EP : 0 for bulk */

  // A
  /* Endpoint descriptor for consumer EP */
  0x07,                    /* Descriptor size */
  CY_U3P_USB_ENDPNT_DESCR, /* Endpoint descriptor type */
  CY_FX_EP_CONSUMER_A,     /* Endpoint address and description */
  CY_U3P_USB_EP_BULK,      /* Bulk endpoint type */
  0x00, 0x04,              /* Max packet size = 1024 bytes */
  0x00, /* Servicing interval for data transfers : 0 for Bulk */

  /* Super speed endpoint companion descriptor for consumer EP */
  0x06,                     /* Descriptor size */
  CY_U3P_SS_EP_COMPN_DESCR, /* SS endpoint companion descriptor type */
  0x00,       /* Max no. of packets in a burst : 0: burst 1 packet at a time */
  0x00,       /* Max streams for bulk EP = 0 (No streams) */
  0x00, 0x00, /* Service interval for the EP : 0 for bulk */

  // B
  /* Endpoint descriptor for consumer EP */
  0x07,                    /* Descriptor size */
  CY_U3P_USB_ENDPNT_DESCR, /* Endpoint descriptor type */
  CY_FX_EP_CONSUMER_B,     /* Endpoint address and description */
  CY_U3P_USB_EP_BULK,      /* Bulk endpoint type */
  0x00, 0x04,              /* Max packet size = 1024 bytes */
  0x00, /* Servicing interval for data transfers : 0 for Bulk */

  /* Super speed endpoint companion descriptor for consumer EP */
  0x06,                     /* Descriptor size */
  CY_U3P_SS_EP_COMPN_DESCR, /* SS endpoint companion descriptor type */
  0x00,       /* Max no. of packets in a burst : 0: burst 1 packet at a time */
  0x00,       /* Max streams for bulk EP = 0 (No streams) */
  0x00, 0x00, /* Service interval for the EP : 0 for bulk */

  // C
  /* Endpoint descriptor for consumer EP */
  0x07,                    /* Descriptor size */
  CY_U3P_USB_ENDPNT_DESCR, /* Endpoint descriptor type */
  CY_FX_EP_CONSUMER_C,     /* Endpoint address and description */
  CY_U3P_USB_EP_BULK,      /* Bulk endpoint type */
  0x00, 0x04,              /* Max packet size = 1024 bytes */
  0x00, /* Servicing interval for data transfers : 0 for Bulk */

  /* Super speed endpoint companion descriptor for consumer EP */
  0x06,                     /* Descriptor size */
  CY_U3P_SS_EP_COMPN_DESCR, /* SS endpoint companion descriptor type */
  0x00,      /* Max no. of packets in a burst : 0: burst 1 packet at a time */
  0x00,      /* Max streams for bulk EP = 0 (No streams) */
  0x00, 0x00 /* Service interval for the EP : 0 for bulk */
};

/* Standard high speed configuration descriptor */
const uint8_t CyFxUSBHSConfigDscr[] __attribute__((aligned(32))) = {
  /* Configuration descriptor */
  0x09,                    /* Descriptor size */
  CY_U3P_USB_CONFIG_DESCR, /* Configuration descriptor type */
  112, 0x00, /* Length of this descriptor and all sub descriptors */ // 8516#55
  0x03, /* Number of interfaces */
  0x01, /* Configuration number */
  0x00, /* COnfiguration string index */
  0x80, /* Config characteristics - bus powered */
  0x64, /* Max power consumption of device (in 2mA unit) : 100mA */

  /* Interface Association Descriptor */
  0x08u, /*  Interface Assoc Descriptor Length      */
  0x0Bu, /*  DescriptorType: Interface association  */
  0x00u, /*  bfirstInterface	                   */
  0x02u, /*  binterface count	                   */
  0x02u, /*  bFunctionClass                         */
  0x00u, /*  bFunctionSubClass                      */
  0x00u, /*  bInterfaceProtocol                     */
  0x00u, /*  iInterface                             */

  
  /* Communication Interface descriptor */
  0x09,                    /* Descriptor size */
  CY_U3P_USB_INTRFC_DESCR, /* Interface Descriptor type */
  0x00,                    /* Interface number */
  0x00,                    /* Alternate setting number */
  0x01,                    /* Number of endpoints */
  0x02,                    /* Interface class : Communication Interface */
  0x02,                    /* Interface sub class */
  0x01,                    /* Interface protocol code */
  0x00,                    /* Interface descriptor string index */

  /* CDC Class-specific Descriptors */
  /* Header functional Descriptor */
  0x05,       /* Descriptors length(5) */
  0x24,       /* Descriptor type : CS_Interface */
  0x00,       /* DescriptorSubType : Header Functional Descriptor */
  0x10, 0x01, /* bcdCDC : CDC Release Number */

  /* Abstract Control Management Functional Descriptor */
  0x04, /* Descriptors Length (4) */
  0x24, /* bDescriptorType: CS_INTERFACE */
  0x02, /* bDescriptorSubType: Abstract Control Model Functional Descriptor */
  0x02, /* bmCapabilities: Supports the request combination of Set_Line_Coding,
           Set_Control_Line_State, Get_Line_Coding and the notification
           Serial_State */

  /* Union Functional Descriptor */
  0x05, /* Descriptors Length (5) */
  0x24, /* bDescriptorType: CS_INTERFACE */
  0x06, /* bDescriptorSubType: Union Functional Descriptor */
  0x00, /* bMasterInterface */
  0x01, /* bSlaveInterface */

  /* Call Management Functional Descriptor */
  0x05, /*  Descriptors Length (5) */
  0x24, /*  bDescriptorType: CS_INTERFACE */
  0x01, /*  bDescriptorSubType: Call Management Functional Descriptor */
  0x00, /*  bmCapabilities: Device sends/receives call management information
            only over the Communication Class Interface. */
  0x01, /*  Interface Number of Data Class interface */

  /* Endpoint Descriptor(Interrupt) */
  0x07,                    /* Descriptor size */
  CY_U3P_USB_ENDPNT_DESCR, /* Endpoint descriptor type */
  CY_FX_EP_INTERRUPT,                    /* Endpoint address and description */
  CY_U3P_USB_EP_INTR,      /* Interrupt endpoint type */
  0x40,
  0x00, /* Max packet size = 64 bytes */
  0x02, /* Servicing interval for data transfers */

  /* Data Interface Descriptor */
  0x09,                    /* Descriptor size */
  CY_U3P_USB_INTRFC_DESCR, /* Interface Descriptor type */
  0x01,                    /* Interface number */
  0x00,                    /* Alternate setting number */
  0x02,                    /* Number of endpoints */
  0x0A,                    /* Interface class: Data interface */
  0x00,                    /* Interface sub class */
  0x00,                    /* Interface protocol code */
  0x00,                    /* Interface descriptor string index */

  /* Endpoint Descriptor(BULK-PRODUCER) */
  0x07,                    /* Descriptor size */
  CY_U3P_USB_ENDPNT_DESCR, /* Endpoint descriptor type */
  CY_FX_EP_UARTOUT,        /* Endpoint address and description */
  CY_U3P_USB_EP_BULK,      /* BULK endpoint type */
  0x00, 0x02,              /* Max packet size = 512 bytes */
  0x00,                    /* Servicing interval for data transfers */

  /* Endpoint Descriptor(BULK- CONSUMER) */
  0x07,                    /* Descriptor size */
  CY_U3P_USB_ENDPNT_DESCR, /* Endpoint descriptor type */
  CY_FX_EP_UARTIN,         /* Endpoint address and description */
  CY_U3P_USB_EP_BULK,      /* Bulk endpoint type */
  0x00, 0x02,              /* Max packet size = 512 bytes */
  0x00,                    /* Servicing interval for data transfers */

  /* Interface descriptor */
  0x09,                    /* Descriptor size */
  CY_U3P_USB_INTRFC_DESCR, /* Interface Descriptor type */
  0x02,                    /* Interface number */
  0x00,                    /* Alternate setting number */
  0x04, /*0x02,*/          /* Number of endpoints */
  0xFF,                    /* Interface class */
  0x00,                    /* Interface sub class */
  0x00,                    /* Interface protocol code */
  0x00,                    /* Interface descriptor string index */

  /* Endpoint descriptor for producer EP */
  0x07,                    /* Descriptor size */
  CY_U3P_USB_ENDPNT_DESCR, /* Endpoint descriptor type */
  CY_FX_EP_PRODUCER,       /* Endpoint address and description */
  CY_U3P_USB_EP_BULK,      /* Bulk endpoint type */
  0x00, 0x02,              /* Max packet size = 512 bytes */
  0x00, /* Servicing interval for data transfers : 0 for bulk */

  // A
  /* Endpoint descriptor for consumer EP */
  0x07,                    /* Descriptor size */
  CY_U3P_USB_ENDPNT_DESCR, /* Endpoint descriptor type */
  CY_FX_EP_CONSUMER_A,     /* Endpoint address and description */
  CY_U3P_USB_EP_BULK,      /* Bulk endpoint type */
  0x00, 0x02,              /* Max packet size = 512 bytes */
  0x00, /* Servicing interval for data transfers : 0 for bulk */

  // B
  /* Endpoint descriptor for consumer EP */
  0x07,                    /* Descriptor size */
  CY_U3P_USB_ENDPNT_DESCR, /* Endpoint descriptor type */
  CY_FX_EP_CONSUMER_B,     /* Endpoint address and description */
  CY_U3P_USB_EP_BULK,      /* Bulk endpoint type */
  0x00, 0x02,              /* Max packet size = 512 bytes */
  0x00, /* Servicing interval for data transfers : 0 for bulk */

  // C
  /* Endpoint descriptor for consumer EP */
  0x07,                    /* Descriptor size */
  CY_U3P_USB_ENDPNT_DESCR, /* Endpoint descriptor type */
  CY_FX_EP_CONSUMER_C,     /* Endpoint address and description */
  CY_U3P_USB_EP_BULK,      /* Bulk endpoint type */
  0x00, 0x02,              /* Max packet size = 512 bytes */
  0x00 /* Servicing interval for data transfers : 0 for bulk */
};

/* Standard full speed configuration descriptor */
const uint8_t CyFxUSBFSConfigDscr[] __attribute__((aligned(32))) = {
  /* Configuration descriptor */
  0x09,                    /* Descriptor size */
  CY_U3P_USB_CONFIG_DESCR, /* Configuration descriptor type */
  98, 0x00, /* Length of this descriptor and all sub descriptors */ // 90
  0x03, /* Number of interfaces */
  0x01, /* Configuration number */
  0x00, /* COnfiguration string index */
  0x80, /* Config characteristics - bus powered */
  0x64, /* Max power consumption of device (in 2mA unit) : 100mA */

  /* Interface Association Descriptor */
  0x08u, /*  Interface Assoc Descriptor Length      */
  0x0Bu, /*  DescriptorType: Interface association  */
  0x00u, /*  bfirstInterface	                   */
  0x02u, /*  binterface count	                   */
  0x02u, /*  bFunctionClass                         */
  0x00u, /*  bFunctionSubClass                      */
  0x00u, /*  bInterfaceProtocol                     */
  0x00u, /*  iInterface                             */

  
  /* Communication Interface descriptor */
  0x09,                    /* Descriptor size */
  CY_U3P_USB_INTRFC_DESCR, /* Interface Descriptor type */
  0x01,                    /* Interface number */
  0x00,                    /* Alternate setting number */
  0x01,                    /* Number of endpoints */
  0x02,                    /* Interface class: Communication interface*/
  0x02,                    /* Interface sub class */
  0x01,                    /* Interface protocol code */
  0x00,                    /* Interface descriptor string index */

  /* CDC Class-specific Descriptors */
  /* Header functional Descriptor */
  0x05,       /* Descriptors length(5) */
  0x24,       /* Descriptor type : CS_Interface */
  0x00,       /* DescriptorSubType : Header Functional Descriptor */
  0x10, 0x01, /* bcdCDC : CDC Release Number */

  /* Abstract Control Management Functional Descriptor */
  0x04, /* Descriptors Length (4) */
  0x24, /* bDescriptorType: CS_INTERFACE */
  0x02, /* bDescriptorSubType: Abstract Control Model Functional Descriptor */
  0x02, /* bmCapabilities: Supports the request combination of Set_Line_Coding,
           Set_Control_Line_State, Get_Line_Coding and the notification
           Serial_State */

  /* Union Functional Descriptor */
  0x05, /* Descriptors Length (5) */
  0x24, /* bDescriptorType: CS_INTERFACE */
  0x06, /* bDescriptorSubType: Union Functional Descriptor */
  0x00, /* bMasterInterface */
  0x01, /* bSlaveInterface */

  /* Call Management Functional Descriptor */
  0x05, /*  Descriptors Length (5) */
  0x24, /*  bDescriptorType: CS_INTERFACE */
  0x01, /*  bDescriptorSubType: Call Management Functional Descriptor */
  0x00, /*  bmCapabilities: Device sends/receives call management information
           only over
            the Communication Class Interface. */
  0x01, /*  Interface Number of Data Class interface */

  /* Endpoint Descriptor(Interrupt) */
  0x07,                    /* Descriptor size */
  CY_U3P_USB_ENDPNT_DESCR, /* Endpoint descriptor type */
  0x01,                    /* Endpoint address and description */
  CY_U3P_USB_EP_INTR,      /* Interrupt endpoint type */
  0x10,
  0x00, /* Max packet size = 16 bytes */
  0x02, /* Servicing interval for data transfers */

  /* Data Interface Descriptor */
  0x09,                    /* Descriptor size */
  CY_U3P_USB_INTRFC_DESCR, /* Interface Descriptor type */
  0x02,                    /* Interface number */
  0x00,                    /* Alternate setting number */
  0x02,                    /* Number of endpoints */
  0x0A,                    /* Interface class: Data interface */
  0x00,                    /* Interface sub class */
  0x00,                    /* Interface protocol code */
  0x00,                    /* Interface descriptor string index */

  /* Endpoint Descriptor(BULK-PRODUCER) */
  0x07,                    /* Descriptor size */
  CY_U3P_USB_ENDPNT_DESCR, /* Endpoint descriptor type */
  0x02,                    /* Endpoint address and description */
  CY_U3P_USB_EP_BULK,      /* BULK endpoint type */
  0x40, 0x00,              /* Max packet size = 64 bytes */
  0x00,                    /* Servicing interval for data transfers */

  /* Endpoint Descriptor(BULK- CONSUMER) */
  0x07,                    /* Descriptor size */
  CY_U3P_USB_ENDPNT_DESCR, /* Endpoint descriptor type */
  0x83,                    /* Endpoint address and description */
  CY_U3P_USB_EP_BULK,      /* Bulk endpoint type */
  0x40, 0x00,              /* Max packet size = 64 bytes */
  0x00,                    /* Servicing interval for data transfers */
  /* Interface descriptor */
  0x09,                    /* Descriptor size */
  CY_U3P_USB_INTRFC_DESCR, /* Interface descriptor type */
  0x00,                    /* Interface number */
  0x00,                    /* Alternate setting number */
  0x04, /*0x02,*/          /* Number of endpoints */
  0xFF,                    /* Interface class */
  0x00,                    /* Interface sub class */
  0x00,                    /* Interface protocol code */
  0x00,                    /* Interface descriptor string index */

  /* Endpoint descriptor for producer EP */
  0x07,                    /* Descriptor size */
  CY_U3P_USB_ENDPNT_DESCR, /* Endpoint descriptor type */
  CY_FX_EP_PRODUCER,       /* Endpoint address and description */
  CY_U3P_USB_EP_BULK,      /* Bulk endpoint type */
  0x40, 0x00,              /* Max packet size = 64 bytes */
  0x00, /* Servicing interval for data transfers : 0 for bulk */

  // A
  /* Endpoint descriptor for consumer EP */
  0x07,                    /* Descriptor size */
  CY_U3P_USB_ENDPNT_DESCR, /* Endpoint descriptor type */
  CY_FX_EP_CONSUMER_A,     /* Endpoint address and description */
  CY_U3P_USB_EP_BULK,      /* Bulk endpoint type */
  0x40, 0x00,              /* Max packet size = 64 bytes */
  0x00, /* Servicing interval for data transfers : 0 for bulk */

  // B
  /* Endpoint descriptor for consumer EP */
  0x07,                    /* Descriptor size */
  CY_U3P_USB_ENDPNT_DESCR, /* Endpoint descriptor type */
  CY_FX_EP_CONSUMER_B,     /* Endpoint address and description */
  CY_U3P_USB_EP_BULK,      /* Bulk endpoint type */
  0x40, 0x00,              /* Max packet size = 64 bytes */
  0x00, /* Servicing interval for data transfers : 0 for bulk */

  // C
  /* Endpoint descriptor for consumer EP */
  0x07,                    /* Descriptor size */
  CY_U3P_USB_ENDPNT_DESCR, /* Endpoint descriptor type */
  CY_FX_EP_CONSUMER_C,     /* Endpoint address and description */
  CY_U3P_USB_EP_BULK,      /* Bulk endpoint type */
  0x40, 0x00,              /* Max packet size = 64 bytes */
  0x00 /* Servicing interval for data transfers : 0 for bulk */
};

/* Standard language ID string descriptor */
const uint8_t CyFxUSBStringLangIDDscr[] __attribute__((aligned(32))) = {
  0x04,                         /* Descriptor size */
  CY_U3P_USB_STRING_DESCR,      /* Device descriptor type */
  0x09,                    0x04 /* Language ID supported */
};

/* Standard manufacturer string descriptor */
const uint8_t CyFxUSBManufactureDscr[] __attribute__((aligned(32))) = {
  18,                    /* Descriptor size */
  CY_U3P_USB_STRING_DESCR, /* Device descriptor type */
  'I', 0x00,
  'T', 0x00,
  'S', 0x00,
  '-', 0x00,
  'W', 0x00,
  'P', 0x00,
  '1', 0x00,
  '0', 0x00
};

/* Standard product string descriptor */
const uint8_t CyFxUSBProductDscr[] __attribute__((aligned(32))) = {
  0x1a,                    /* Descriptor size */
  CY_U3P_USB_STRING_DESCR, /* Device descriptor type */
  'R',                     0x00, 'U', 0x00, 'v', 0x00, '0', 0x00,
  'a',                     0x00, '-', 0x00, 'F', 0x00, 'x', 0x00,
  '3',                     0x00, '_', 0x00, 'R', 0x00, 'O', 0x00
};

const uint8_t CyFxUSBSerialNumDesc[] __attribute((alligned(32))) = {
    16,                           /* Descriptor size */
    CY_U3P_USB_STRING_DESCR,        /* Device descriptor type */
    /* Custom serial number part */
    FX3_SERIAL_NUMBER_0,0,
    FX3_SERIAL_NUMBER_1,0,
    FX3_SERIAL_NUMBER_2,0,
    FX3_SERIAL_NUMBER_3,0,
    FX3_SERIAL_NUMBER_4,0,
    FX3_SERIAL_NUMBER_5,0,
    0,0,                            /* long word align */
};

/* Place this buffer as the last buffer so that no other variable / code shares
 * the same cache line. Do not add any other variables / arrays in this file.
 * This will lead to variables sharing the same cache line. */
const uint8_t CyFxUsbDscrAlignBuffer[32] __attribute__((aligned(32)));

/* [ ] */
