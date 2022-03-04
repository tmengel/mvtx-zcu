import time
import datetime
import logging
import random
import collections
import os
import ru_transceiver

class EyeScan(object):
    """Encapsulates Eye scan functionality"""

    def __init__(self, transceiver):
        self.transceiver = transceiver

        # parameters
        self.offset_v = 0
        self.offset_v_ut = 0
        self.offset_h = 0
        self.prescale = 0
        self.is_lpm = True
        self.eye_scan_horizontal_max = 128
        self.eye_scan_vertical_max = 127
        self.logger = logging.getLogger("EyeScan")

    def initialize(self, is_lpm_equalizer=True, horizontal_max=128, vertical_max=127):
        """Initialize eye scan functionality"""
        self._set_sdata_mask(20)
        self._set_qual_mask()
        self.is_lpm = is_lpm_equalizer

        self._activate_eye_scan()
        self._reset_receiver_pma()

        self.eye_scan_horizontal_max = horizontal_max
        self.eye_scan_vertical_max = vertical_max


    def _read_counts(self):
        """ Read sample and error count and return a tuple of (samples,errors) """
        samples_scaled, errors, prescale = self._read_counts_raw()
        samples = 20 * samples_scaled * 2**(1 + prescale)
        return (samples, errors)

    def _set_offset(self, offset_h, offset_v):
        """Set vertical and horizontal offset for an eye scan"""
        self._set_offset_h(offset_h)
        self._set_offset_v(offset_v)

    def _set_offset_v(self, offset_v, offset_ut=1):
        """Set vertical offset for an eye scan (including UT setting)"""
        self.offset_v = offset_v
        self.offset_v_ut = offset_ut
        self._set_prescale_offset_v()

    def _set_prescale(self, prescale):
        """ Set prescale in the range of 2^(1+prescale) """
        self.prescale = prescale
        self._set_prescale_offset_v()

    def _eye_scan_point_setup(self, offset_h=0, offset_v=0, prescale=0, ut_sign=0, readback=False, verbose=False):
        """Setup values for eye scan on specific point"""
        if verbose:
            self.logger.info(
                "Eye scan point setup: offset_h: %d, offset_v = %d, prescale = %d, ut_sign = %d",
                offset_h,
                offset_v,
                prescale,
                ut_sign)

        self._set_control_state(0)
        self._set_offset_h(offset_h)
        self.offset_v = offset_v
        self.prescale = prescale
        self.offset_v_ut = ut_sign
        self._set_prescale_offset_v()

        if readback:
            self._check_eye_scan_settings(offset_h, offset_v, prescale, ut_sign)

    def _eye_scan_point_start(self, commitTransaction=True, verbose=False):
        """Start eye scan on point (previously setup)"""
        if verbose:
            self.logger.info("Start eye scan at configured point")
        self._set_control_state(1, commitTransaction=commitTransaction)

    def _is_eye_scan_point_done(self, verbose=False):
        """Check if eye scan on point is finished. Return True if the statemachine is done, False otherwise"""
        state = self._read_control_state()
        done = state[0] == 1
        if done:
            self._set_control_state(0)
        if done and verbose:
            self.logger.info("Eye scan point done, done: %d, state: %d", state[0], state[1])
        return done

    def _eye_scan_point_ut(self, offset_h, offset_v, prescale, ut_sign, func):
        """Perform an eye scan at given offset points (horizontal, vertical, ut_sign), with given prescale"""

        self._eye_scan_point_setup(offset_h, offset_v, prescale, ut_sign)

        self._eye_scan_point_start()
        time.sleep(0.05)
        while not self._is_eye_scan_point_done():
            if func:
                func()
            else:
                time.sleep(0.1)
        cnt = self._read_counts()
        return cnt

    def _eye_scan_point(self, offset_h, offset_v, prescale, ber, func):
        """Perform an eye scan at specific point, given offsets, prescale and BER setting (max prescale)"""
        done = False
        cps = prescale  # current prescale
        maxps = ber
        minErrors = 10

        cnt = [0, 0]
        while not done:
            cnt1 = self._eye_scan_point_ut(offset_h, offset_v, cps, 0, func)
            if self.is_lpm:
                cnt2 = (0, 0)
            else:  # DFE
                cnt2 = self._eye_scan_point_ut(offset_h, offset_v, cps, 1, func)
            cnt[0] += cnt1[0] + cnt2[0]
            cnt[1] += cnt1[1] + cnt2[1]

            samples = cnt[0]
            errors = cnt[1]
            if samples < errors and cps > 0:
                cps = max(cps - 2, 0)
            elif errors < minErrors and cps < maxps:
                cps = min(cps + 1, maxps)
            else:
                done = True

        return cnt

    def eye_scan(
            self,
            v_steps=5,
            h_steps=5,
            prescale=4,
            ber=10,
            output_file=None,
            verbose=False,
            table=None,
            no_center=False,
            func=None):
        """Perform an eye scan measurement, defining Vertical steps,
        horizontal steps, default prescaling, ber(maximum prescaling)
        and an output file. An additional function can be added to be run during scanning.
        The output is a table with all scanned
        points. For resuming a scan, resume_eye_scan can be called.
        """
        horz_step = int(round(self.eye_scan_horizontal_max / h_steps))
        if v_steps == 0:
            vert_step = 0
        else:
            vert_step = int(round(self.eye_scan_vertical_max / v_steps))
        range_i = range(-h_steps, h_steps + 1)
        range_j = range(-v_steps, v_steps + 1)
        iterations = len(range_i) * len(range_j)
        it_cnt = 0

        if table is None:
            table = {}

        self.logger.info("Run eye scan with {0} scans".format(iterations))
        for i in range_i:
            point_x = min(i * horz_step, self.eye_scan_horizontal_max)
            point_x = max(point_x, -self.eye_scan_horizontal_max)
            zeroCnt = 5
            zeroPt = 0
            for j in range_j:
                point_y = min(j * vert_step, self.eye_scan_vertical_max)
                point_y = max(point_y, -self.eye_scan_vertical_max)

                if (point_x, point_y) not in table:
                    if zeroCnt == 0 and point_y < zeroPt and no_center:
                        cnt = (-1, 0)
                        if verbose:
                            self.logger.info(
                                "Skip X:{0}, Y:{1}; Within zero bound".format(point_x, point_y))
                    else:
                        start = time.time()
                        cnt = self._eye_scan_point(point_x, point_y, prescale, ber, func)
                        runtime = time.time() - start
                        if cnt[1] == 0:
                            zeroCnt -= 1
                            if zeroCnt == 0:
                                zeroPt = -point_y
                        if verbose:
                            self.logger.info("Scan X:{0}, Y:{1}; Samples: {2}, Errors: {3}; Time: {4:.2f}".format(
                                point_x, point_y, cnt[0], cnt[1],runtime))

                    table[(point_x, point_y)] = cnt
                    if output_file:
                        output_file.write("{0},{1},{2},{3},{4}\n".format(
                            datetime.datetime.utcnow(), point_x, point_y, cnt[0], cnt[1]))
                        output_file.flush()
                it_cnt += 1
                if it_cnt % 100 == 0:
                    self.logger.info("Scans: {0}/{1}".format(it_cnt, iterations))

        return table

    def resume_eye_scan(self, output_file_name, v_steps=5, h_steps=5, prescale=4,
                        ber=10, verbose=False, no_center=False, func=None):
        """Resume a previously started eye scan.
        Reads scanned points from an old file and resumes from the last point
        """
        table = {}
        # fill table
        with open(output_file_name, 'r') as ofile:
            for line in ofile:
                dat = line.rstrip("\n").split(",")
                table[(int(dat[1]), int(dat[2]))] = (int(dat[3]), int(dat[4]))

        self.logger.info("Recovered {0} data points".format(len(table)))

        return self.eye_scan(v_steps, h_steps, prescale, ber, open(
            output_file_name, 'a'), verbose, table, no_center, func)


    def eye_scan_adaptive(
            self,
            v_steps=5,
            h_steps=5,
            prescale=4,
            ber=10,
            threshold = 50,
            output_file_name=None,
            resume=False,
            no_center=False,
            verbose=False,
            func=None):
        """Perform an adaptive eye scan measurement, defining Vertical steps,
        horizontal steps, default prescaling, ber(maximum prescaling)
        and an output file. An additional function can be added to be run during scanning.
        The output is a table with all scanned
        points. For resuming a scan, resume=True.
        Runs a Scan with minimal prescale through the whole range. All points below
        threshold errors will be stored and rerun with a higher prescale in a second pass.
        Continues until BER prescale is reached or no points are open.
        """

        table = {}
        # fill table
        if resume and os.path.isfile(output_file_name):
            with open(output_file_name, 'r') as ofile:
                for line in ofile:
                    dat = line.rstrip("\n").split(",")
                    table[(int(dat[1]), int(dat[2]))] = (int(dat[3]), int(dat[4]))
            self.logger.info("Recovered {0} data points".format(len(table)))
            output_file = open(output_file_name,'a')
        else:
            output_file = open(output_file_name,'w')

        horz_step = int(round(self.eye_scan_horizontal_max / h_steps))
        if v_steps == 0:
            vert_step = 0
        else:
            vert_step = int(round(self.eye_scan_vertical_max / v_steps))
        range_i = [-x for x in range(h_steps,0,-1)] + list(range(0,h_steps+1))
        range_j = [-i for i in range(v_steps,0,-1)] + list(range(v_steps,0,-1))+ [0]
        #range_i = range(-h_steps, h_steps + 1)
        #range_j = range(-v_steps, v_steps + 1)
        it_cnt = 0

        if table is None:
            table = {}

        pointsToRun = collections.OrderedDict()

        for i in range_i:
            point_x = min(i * horz_step, self.eye_scan_horizontal_max)
            point_x = max(point_x, -self.eye_scan_horizontal_max)
            pointsToRun[point_x] = []
            for j in range_j:
                point_y = min(j * vert_step, self.eye_scan_vertical_max)
                point_y = max(point_y, -self.eye_scan_vertical_max)
                if (point_x,point_y) not in table or table[(point_x,point_y)][1] <= threshold:
                    pointsToRun[point_x].append(point_y)
        scan_pass = 1
        ps = prescale
        nr_points = sum([len(x) for x in pointsToRun.values()])
        while nr_points > 0:
            it_cnt = 0
            next_pointsToRun = collections.OrderedDict()
            nr_points = sum([len(x) for x in pointsToRun.values()])
            zero_skipped = 0
            self.logger.info("Run scan, pass %d, prescale: %d, scans: %d",scan_pass,ps,nr_points)

            for point_x in pointsToRun.keys():
                zerosample_pos = 0
                zerosample_neg = 0
                next_pointsToRun[point_x] = []
                for point_y in pointsToRun[point_x]:
                    start = time.time()
                    if no_center and point_y > 0 and zerosample_pos > 0:
                        cnt = (zerosample_pos, 0)
                        zero_skipped +=1
                        if verbose:
                            self.logger.info("Scan X:%d, Y:%d; Within zero bound, skip",point_x, point_y)
                    elif no_center and point_y < 0 and zerosample_neg > 0:
                        cnt = (zerosample_neg,0)
                        zero_skipped +=1
                        if verbose:
                            self.logger.info("Scan X:%d, Y:%d; Within zero bound, skip",point_x, point_y)
                    else:
                        cnt = self._eye_scan_point(point_x, point_y, ps, ps, func)
                        if cnt[1] == 0:
                            if point_y > 0:
                                zerosample_pos = cnt[0]
                            elif point_y < 0:
                                zerosample_neg = cnt[0]

                    runtime = time.time() - start
                    if verbose:
                        self.logger.info("Scan X:%d, Y:%d; Samples: %d, Errors: %d; Time: %.2f",point_x, point_y, cnt[0], cnt[1],runtime)

                    if cnt[1] <= threshold and ps < ber:
                        next_pointsToRun[point_x].append(point_y)
                        if verbose:
                            self.logger.info("Add Point (%d,%d) to list for next iteration",point_x,point_y)

                    table[(point_x, point_y)] = cnt
                    if output_file:
                        output_file.write("{0},{1},{2},{3},{4}\n".format(
                            datetime.datetime.utcnow(), point_x, point_y, cnt[0], cnt[1]))
                        output_file.flush()
                    it_cnt += 1
                    if it_cnt % 100 == 0:
                        self.logger.info("Scans: %d/%d",it_cnt,nr_points)
            ps += 1
            pointsToRun = next_pointsToRun
            scan_pass += 1
            nr_points = sum([len(x) for x in pointsToRun.values()])
            self.logger.info("Zero skipped: %d, Points for next run: %d",zero_skipped, nr_points)
        return table

class EyeScanGtx(EyeScan):
    """Eye scan functionality for GTX transceiver"""
    # DRP addresses
    ES_VERT_OFFSET_PRESCALE = 0x3B
    ES_HORZ_OFFSET = 0x3C
    ES_SDATA_MASK = (0x3A, 0x39, 0x38, 0x37, 0x36)
    ES_QUAL_MASK = range(0x31, 0x36)
    ES_CONTROL = 0x3D
    ES_CONTROL_STATE = 0x151
    ES_SAMPLE_COUNT = 0x150
    ES_ERROR_COUNT = 0x14F
    PMA_RSV2 = 0x82

    def __init__(self, transceiver):
        super(EyeScanGth, self).__init__(transceiver)

    def _reset_receiver_pma(self):
        # reset pma
        tmp = self.transceiver.read(2)
        tmp = tmp | (1 << 2)
        self.transceiver.write(2, tmp)
        tmp = tmp & ~(1 << 2)
        self.transceiver.write(2, tmp)

    def _activate_eye_scan(self):
        val = self.transceiver.read_drp(self.PMA_RSV2)
        val = val | (1 << 5)
        self.transceiver.write_drp(self.PMA_RSV2, val)

    def _set_qual_mask(self):
        """Set qualifier mask for Eye scan"""
        for i in self.ES_QUAL_MASK:
            self.transceiver.write_drp(i, 0xFFFF)

    def _set_control_state(self, run=1, commitTransaction=True):
        """Set control state for ES_CONTROL"""
        data = run | (1 << 8) | (1 << 9)
        self.transceiver.write_drp(self.ES_CONTROL, data, commitTransaction=commitTransaction)

    def _read_control_state(self):
        """ Return a tuple of (done,state) """
        data = self.transceiver.read_drp(self.ES_CONTROL_STATE)
        done = data & 0x1
        state = (data >> 1) & 0xF
        return (done, state)


    def _read_counts_raw(self):
        """ Read raw sample and error counters from drp port, return as tumple of (samples,errors, prescale)"""
        samples_scaled = self.transceiver.read_drp(self.ES_SAMPLE_COUNT)
        errors = self.transceiver.read_drp(self.ES_ERROR_COUNT)

        return (samples_scaled, errors, self.prescale)

    def _set_sdata_mask(self, bus_width):
        """Set the sdata mask"""
        # assume 40 bit mask
        es_sdata_mask = [0xFFFF, 0xFFFF, 0xFF00, 0x0000, 0x0000]

        if bus_width == 20:
            es_sdata_mask[3] = 0x000F
            es_sdata_mask[4] = 0xFFFF

        for mask_addr, mask_data in zip(self.ES_SDATA_MASK, es_sdata_mask):
            self.transceiver.write_drp(mask_addr, mask_data)

    def _set_offset_h(self, offset_h):
        """set horizontal offset for an eye scan"""
        self.offset_h = offset_h

        data = offset_h & 0xFFF
        self.transceiver.write_drp(self.ES_HORZ_OFFSET, data)

    def _set_prescale_offset_v(self):
        """set vertical prescale offset"""
        offset_ut = self.offset_v_ut
        sign = 0
        if self.offset_v < 0:
            sign = 1
        mag = abs(self.offset_v) & 0x7F
        data = mag | sign << 7 | offset_ut << 8
        data = data | ((self.prescale & 0x1F) << 11)
        self.transceiver.write_drp(self.ES_VERT_OFFSET_PRESCALE, data)

    def _check_eye_scan_settings(self, offset_h, offset_v, prescale, ut_sign):
        offset_h_reg = self.transceiver.read_drp(self.ES_HORZ_OFFSET)
        offset_v_reg = self.transceiver.read_drp(self.ES_VERT_OFFSET_PRESCALE)
        offset_h_rb = offset_h_reg & 0xFFF

        offset_v_rb = offset_v_reg & 0x7F
        if(offset_v_reg >> 7 & 1):
            offset_v_rb = -offset_v_rb
        ut_sign_rb = offset_v_reg >> 8 & 1
        prescale_rb = (offset_v_reg >> 11) & 0x1F

        if bin(offset_h_rb) != bin(offset_h % 0x1000):
            self.logger.warning("Mismatch in offset_h readback: (Read: %#x, Wrote: %#x)", offset_h_rb,
                                (offset_h % 0x1000))
        if offset_v_rb != offset_v:
            self.logger.warning("Mismatch in offset_v readback: (Read: %#x, Wrote: %#x)", offset_v_rb, offset_v)
        if ut_sign_rb != ut_sign:
            self.logger.warning("Mismatch in ut_sign readback: (Read: %#x, Wrote: %#x)", ut_sign_rb, ut_sign)
        if prescale_rb != prescale:
            self.logger.warning("Mismatch in prescale readback: (Read: %#x, Wrote: %#x)", prescale_rb, prescale)


class EyeScanGth(EyeScan):
    """Eye scan functionality for GTX transceiver"""
    # DRP addresses
    ES_CONTROL = 0x3C
    ES_EYE_SCAN_EN = 0x3C
    ES_PRESCALE = 0x3C
    ES_QUAL_MASK = (0x48,0x47,0x46,0x45,0x44)
    ES_SDATA_MASK = (0x4D, 0x4C, 0x4B, 0x4A, 0x49)
    ES_HORZ_OFFSET = 0x4F
    ES_VERT_OFFSET = 0x97
    ES_CONTROL_STATE = 0x153
    ES_SAMPLE_COUNT = 0x152
    ES_ERROR_COUNT = 0x151

    #prescale: 0x030X: ERDET[9]=1,EYE_SCAN[8]=1

    #vertical offset: #000ABCDEEEEEEEFF
    #A: RX_AFE_CM_EN
    #B: RX_CAPFF_SARC_ENB
    #C: RX_EYESCAN_VS_NEG_DIR
    #D: RX_EYESCAN_VS_UT_SIGN
    #E: RX_EYESCAN_VS_CODE
    #F: RX_EYESCAN_VS_RANGE # 00 -> 1.5mV, 01 -> 1.8mV, 10 -> 2.2mV, 11 -> 2.8mV

    #ES_VERT_OFFSET_PRESCALE = 0x3B


    def __init__(self, transceiver,vertical_range=0):
        super(EyeScanGth, self).__init__(transceiver)

        assert len(self.transceiver.transceivers) == 1, "GTH frontend with multiple transceivers not supported"

        self.eyescan_vs_range = vertical_range
        self.vert_offset_defaults = 0
        self.horz_offset_defaults = 0

    def get_vertical_range(self):
        """Return the vertical range per code in mV"""
        ranges = [1.5,1.8,2.2,2.8]
        return ranges[self.eyescan_vs_range]

    def initialize(self):
        super(EyeScanGth, self).initialize()

        self.vert_offset_defaults = self.transceiver.read_drp(self.ES_VERT_OFFSET) & (1<<11 | 1<<12)
        self.horz_offset_defaults = self.transceiver.read_drp(self.ES_HORZ_OFFSET) & 0x000F


    def _reset_receiver_pma(self):
        self.transceiver.reset_receivers()

    def _activate_eye_scan(self):
        self.transceiver.write_drp(self.ES_EYE_SCAN_EN, 0x0300)

    def _set_qual_mask(self):
        """Set qualifier mask for Eye scan"""
        for i in self.ES_QUAL_MASK:
            self.transceiver.write_drp(i, 0xFFFF)

    def _set_control_state(self, run=1, commitTransaction=True):
        """Set control state for ES_CONTROL"""
        data = (run<<10) | (1 << 8) | (1 << 9) | self.prescale
        self.transceiver.write_drp(self.ES_CONTROL, data, commitTransaction=commitTransaction)

    def _read_control_state(self):
        """ Return a tuple of (done,state) """
        data = self.transceiver.read_drp(self.ES_CONTROL_STATE)
        done = data & 0x1
        state = (data >> 1) & 0xF
        return (done, state)


    def _read_counts_raw(self):
        """ Read raw sample and error counters from drp port, return as tumple of (samples,errors, prescale)"""
        samples_scaled = self.transceiver.read_drp(self.ES_SAMPLE_COUNT)
        errors = self.transceiver.read_drp(self.ES_ERROR_COUNT)

        return (samples_scaled, errors, self.prescale)

    def _set_sdata_mask(self, bus_width):
        """Set the sdata mask"""
        # assume 40 bit mask
        es_sdata_mask = [0xFFFF, 0xFFFF, 0xFF00, 0x0000, 0x0000]

        if bus_width == 20:
            es_sdata_mask[3] = 0x000F
            es_sdata_mask[4] = 0xFFFF

        for mask_addr, mask_data in zip(self.ES_SDATA_MASK, es_sdata_mask):
            self.transceiver.write_drp(mask_addr, mask_data)

    def _set_offset_h(self, offset_h):
        """set horizontal offset for an eye scan"""
        self.offset_h = offset_h

        data = ( (offset_h&0xFFF) << 4) | self.horz_offset_defaults
        self.transceiver.write_drp(self.ES_HORZ_OFFSET, data)

    def _set_offset_v(self, offset_v, offset_ut=1):
        """Set vertical offset for an eye scan (including UT setting)"""
        self.offset_v = offset_v
        self.offset_v_ut = offset_ut

        sign = 0
        if self.offset_v < 0:
            sign = 1

        mag = abs(self.offset_v) & 0x7F
        vscale = self.eyescan_vs_range

        data = self.vert_offset_defaults | (sign << 10) | (self.offset_v_ut << 9) | (mag << 2) | vscale

        self.transceiver.write_drp(self.ES_VERT_OFFSET, data)

    def _set_prescale(self, prescale):
        """ Set prescale in the range of 2^(1+prescale) """
        self.prescale= prescale
        self.transceiver.write_drp(self.ES_PRESCALE,0x0300 | self.prescale)


    def _set_prescale_offset_v(self):
        """set vertical prescale offset"""
        self._set_prescale(self.prescale)
        self._set_offset_v(self.offset_v,self.offset_v_ut)

    def _check_eye_scan_settings(self, offset_h, offset_v, prescale, ut_sign):
        offset_h_reg = self.transceiver.read_drp(self.ES_HORZ_OFFSET)
        offset_v_reg = self.transceiver.read_drp(self.ES_VERT_OFFSET)
        prescale_reg = self.transceiver.read_drp(self.ES_PRESCALE)

        offset_h_rb = offset_h_reg & 0xFFF
        prescale_rb = prescale_reg & 0x0F

        offset_v_rb = (offset_v_reg>>2)&0x7F

        sign = (offset_v_reg>>10)&0x1
        if sign:
            offset_v_rb = -offset_v_rb
        ut_sign_rb = (offset_v_reg >> 9) & 1

        if bin(offset_h_rb) != bin(offset_h % 0x1000):
            self.logger.warning("Mismatch in offset_h readback: (Read: %#x, Wrote: %#x)", offset_h_rb,
                                (offset_h % 0x1000))
        if offset_v_rb != offset_v:
            self.logger.warning("Mismatch in offset_v readback: (Read: %#x, Wrote: %#x)", offset_v_rb, offset_v)
        if ut_sign_rb != ut_sign:
            self.logger.warning("Mismatch in ut_sign readback: (Read: %#x, Wrote: %#x)", ut_sign_rb, ut_sign)
        if prescale_rb != prescale:
            self.logger.warning("Mismatch in prescale readback: (Read: %#x, Wrote: %#x)", prescale_rb, prescale)
