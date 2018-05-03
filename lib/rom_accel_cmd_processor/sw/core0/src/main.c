// Copyright (C) 2017 Philipp Holzinger
// Copyright (C) 2017 Martin Stumpf
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

#include <stdint.h>
#include <stdlib.h>
#include "address_config.h"

#include "op_encoding.h"

static volatile uint32_t start_execution = 0;
static volatile uint32_t execution_done = 0;

#define INTERRUPT_TO_DATAMOVER 0
#define INTERRUPT_TO_PE 1
#define INTERRUPT_TO_PACKETPROCESSOR 2

#define fire_interrupt(target) { *((volatile uint32_t*)(SEND_INTERRUPT)) = target; }
#define read_64(base, offset) (*((volatile uint64_t*)((base + offset))))
#define read_32(base, offset) (*((volatile uint32_t*)((base + offset))))
#define read_16(base, offset) (*((volatile uint16_t*)((base + offset))))
#define read_8(base, offset) (*((volatile uint8_t*)((base + offset))))
#define write_64(base, offset, value) \
    {*((volatile uint64_t*)((base) + (offset)))=(value);}
#define write_32(base, offset, value) \
    {*((volatile uint32_t*)((base) + (offset)))=(value);}
#define write_16(base, offset, value) \
    {*((volatile uint16_t*)((base) + (offset)))=(value);}
#define write_8(base, offset, value) \
    {*((volatile uint8_t*)((base) + (offset)))=(value);}

#define append(var, size, val) \
    { (var) = ((var)<<(size)) | ((val)&( (1<<(size))-1 )); }

void handle_interrupt_from_datamover(){
    execution_done = 1;
}

void handle_interrupt_from_packetprocessor(){
    start_execution = 1;
    execution_done = 0;
}

static inline uint32_t compute_bpp(uint16_t color_model){
    return (uint32_t)get_pixel_storage(color_model);
}

static inline uint32_t pe_encode_op(uint8_t color, uint8_t border,
                                    uint8_t kernel, uint8_t norm_and_thresh){

    uint32_t result = 0;

    append(result, 1, color);
    append(result, 2, border);
    append(result, 3, kernel);
    append(result, 1, norm_and_thresh);

    return result;

}

#define write_mask(dst_offset, src){                                        \
    uint32_t* write_mask_dst = (uint32_t*)(BASE_ADDR_CFG_PE + dst_offset);  \
    uint32_t write_mask_i;                                                  \
    for(write_mask_i = 0; write_mask_i < MASK_SIZE; write_mask_i++){        \
        write_mask_dst[write_mask_i] = (src)[write_mask_i];                 \
    }                                                                       \
}

static inline void write_task_config_to_pe( fpga_operation_type_t task,
                                            fpga_colormodel_t color_model,
                                            fpga_borderhandling_t border_conf,
                                            uint16_t normalization, uint16_t threshold){

    uint8_t color = 1;
    switch(color_model){
        case UINT16_GRAY_SCALE:
            color = 1;
            break;
        case UINT8_RGB:
            color = 0;
            break;
    }

    uint32_t window_width = 0;
    uint32_t window_height = 0;

    uint8_t op_type = 0; 
    uint32_t normalize_val = normalization;
    uint32_t threshold_val = threshold;
    switch(task){
        case SOBELX3x3:
            write_mask(PE_CFG_COEFFS0, sobelX_3x3_mask);
            op_type = 0;
            window_width  = 3;
            window_height = 3;
            break;
        case SOBELY3x3:
            write_mask(PE_CFG_COEFFS0, sobelY_3x3_mask);
            op_type = 0;
            window_width  = 3;
            window_height = 3;
            break;
        case SOBELXY3x3:
            write_mask(PE_CFG_COEFFS0, sobelX_3x3_mask);
            write_mask(PE_CFG_COEFFS1, sobelY_3x3_mask);
            op_type = 1;
            window_width  = 3;
            window_height = 3;
            break;
        case SOBELX5x5:
            write_mask(PE_CFG_COEFFS0, sobelX_5x5_mask);
            op_type = 0;
            window_width  = 5;
            window_height = 5;
            break;
        case SOBELY5x5:
            write_mask(PE_CFG_COEFFS0, sobelX_5x5_mask);
            op_type = 0;
            window_width  = 5;
            window_height = 5;
            break;
        case SOBELXY5x5:
            write_mask(PE_CFG_COEFFS0, sobelX_5x5_mask);
            write_mask(PE_CFG_COEFFS1, sobelY_5x5_mask);
            op_type = 1;
            window_width  = 5;
            window_height = 5;
            break;
        case GAUSS3x3:
            write_mask(PE_CFG_COEFFS0, gauss_3x3_mask);
            op_type = 0;
            normalize_val = gauss_3x3_normalization;
            window_width  = 3;
            window_height = 3;
            break;
        case GAUSS5x5:
            write_mask(PE_CFG_COEFFS0, gauss_5x5_mask);
            op_type = 0;
            normalize_val = gauss_5x5_normalization;
            window_width  = 5;
            window_height = 5;
            break;
        case MIN_FILTER3x3:
            op_type = 3;
            window_width  = 3;
            window_height = 3;
            break;
        case MIN_FILTER5x5:
            op_type = 3;
            window_width  = 5;
            window_height = 5;
            break;
        case MAX_FILTER3x3:
            op_type = 4;
            window_width  = 3;
            window_height = 3;
            break;
        case MAX_FILTER5x5:
            op_type = 4;
            window_width  = 5;
            window_height = 5;
            break;
        case MEDIAN_FILTER3x3:
            op_type = 2;
            window_width  = 3;
            window_height = 3;
            break;
        case MEDIAN_FILTER5x5:
            op_type = 2;
            window_width  = 5;
            window_height = 5;
            break;
        case CUSTOM_FILTER3x3:
            write_mask(PE_CFG_COEFFS0, (volatile int32_t*)(BASE_ADDR_CFG+CFG_MASK0));
            write_mask(PE_CFG_COEFFS1, (volatile int32_t*)(BASE_ADDR_CFG+CFG_MASK1));
            op_type = 1;
            window_width  = 3;
            window_height = 3;
            break;
        case CUSTOM_FILTER5x5:
            write_mask(PE_CFG_COEFFS0, (volatile int32_t*)(BASE_ADDR_CFG+CFG_MASK0));
            write_mask(PE_CFG_COEFFS1, (volatile int32_t*)(BASE_ADDR_CFG+CFG_MASK1));
            op_type = 1;
            window_width  = 5;
            window_height = 5;
            break;
    }

    uint8_t border = 0;
    switch(border_conf){
        case CLAMP_TO_ZERO:
            border = 1;
            break;
        case CLAMP_TO_EDGE:
            border = 2;
            break;
    }

    uint32_t pe_op;
    if(op_type == 0 && normalize_val != 0){
        write_32(BASE_ADDR_CFG_PE, PE_CFG_NORMALIZE_VAL, normalize_val);
        pe_op = pe_encode_op(color, border, op_type, 1);
    }
    else if (op_type == 1 && threshold_val != 0){
        write_32(BASE_ADDR_CFG_PE, PE_CFG_THRESHOLD_VAL, threshold_val);
        pe_op = pe_encode_op(color, border, op_type, 1);
    }
    else {
        pe_op = pe_encode_op(color, border, op_type, 0);
    }

    write_32(BASE_ADDR_CFG_PE, PE_CFG_WINDOW_WIDTH, window_width);
    write_32(BASE_ADDR_CFG_PE, PE_CFG_WINDOW_HEIGHT, window_height);
    write_32(BASE_ADDR_CFG_PE, PE_CFG_OPERATION, pe_op);

}

static inline void run_computation(){

    // read config
    uint32_t task               = read_16(BASE_ADDR_CFG, CFG_TASK);
    uint32_t normalization      = read_16(BASE_ADDR_CFG, CFG_NORMALIZATION);
    uint32_t threshold          = read_16(BASE_ADDR_CFG, CFG_THRESHOLD);
    uint16_t color_model        = read_8(BASE_ADDR_CFG, CFG_COLOR_MODEL);
    uint16_t border_handling    = read_8(BASE_ADDR_CFG, CFG_BORDER_HANDLING);
    uint32_t img_width          = read_32(BASE_ADDR_CFG, CFG_IMG_WIDTH);
    uint32_t img_height         = read_32(BASE_ADDR_CFG, CFG_IMG_HEIGHT);
    uint64_t addr_src           = read_64(BASE_ADDR_CFG, CFG_SRC_ADDR);
    uint64_t addr_dst           = read_64(BASE_ADDR_CFG, CFG_DST_ADDR);

    // compute config values
    uint32_t bytes_per_pixel = compute_bpp(color_model); 
    //uint64_t size_in = (uint64_t)img_width * (uint64_t)img_height
    //                                       * (uint64_t)bytes_per_pixel;
    uint64_t size_in = img_width * img_height * bytes_per_pixel;
    uint64_t size_out = size_in;

    // write config to pe
    write_32(BASE_ADDR_CFG_PE, PE_CFG_IMG_WIDTH, img_width);
    write_32(BASE_ADDR_CFG_PE, PE_CFG_IMG_HEIGHT, img_height);
    write_32(BASE_ADDR_CFG_PE, PE_CFG_IMG_SIZE, img_width*img_height);
    write_task_config_to_pe(task, color_model, border_handling, normalization, threshold);

    // reset pe
    fire_interrupt(INTERRUPT_TO_PE);

    // write config to datamover
    write_64(BASE_ADDR_CFG_DATAMOVER, DATAMOVER_CFG_ADDR_IN,  addr_src);
    write_64(BASE_ADDR_CFG_DATAMOVER, DATAMOVER_CFG_ADDR_OUT, addr_dst);
    write_64(BASE_ADDR_CFG_DATAMOVER, DATAMOVER_CFG_SIZE_IN,  size_in);
    write_64(BASE_ADDR_CFG_DATAMOVER, DATAMOVER_CFG_SIZE_OUT, size_out);

    // start datamover
    fire_interrupt(INTERRUPT_TO_DATAMOVER);

    // wait for datamover to be done
    while(!execution_done){/*do nothing*/}
    execution_done = 0;

    // signal packet processor that we are done
    fire_interrupt(INTERRUPT_TO_PACKETPROCESSOR);

}



int main(){

    while(1){
        if(start_execution){
            start_execution = 0;
            run_computation();
        }
    }

    return 0;
}
