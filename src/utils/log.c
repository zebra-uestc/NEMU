/***************************************************************************************
* Copyright (c) 2014-2021 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <utils.h>
#include <malloc.h>
// control when the log is printed, unit: number of instructions
#define LOG_START (0)
// restrict the size of log file
#define LOG_END   (1024 * 1024 * 50)
#define SMALL_LOG_ROW_NUM (100 * 1024) // row number
uint64_t record_row_number = 0;
FILE *log_fp = NULL;
char *log_filebuf;
bool enable_small_log = false;
void init_log(const char *log_file, const bool small_log) {
  if (log_file == NULL) return;
  log_fp = fopen(log_file, "w");
  Assert(log_fp, "Can not open '%s'", log_file);
  enable_small_log = small_log;
  if (enable_small_log)
    log_filebuf = (char *)malloc(sizeof(char) * SMALL_LOG_ROW_NUM * 300);
}

bool log_enable() {
  extern uint64_t g_nr_guest_instr;
  return (g_nr_guest_instr >= LOG_START) && (g_nr_guest_instr <= LOG_END);
}

void log_flush() {
  record_row_number ++;
  if(record_row_number > SMALL_LOG_ROW_NUM){
    // rewind(log_fp);
    record_row_number = 0;
  }
}
void log_close(){
  if (enable_small_log == false) return;
  if (log_fp == NULL) return;
  // fprintf(log_fp, "%s", log_filebuf);
  for (int i = 0; i < record_row_number; i++)
  {
    fprintf(log_fp, "%s", log_filebuf + i * 300);
  }
  fclose(log_fp);
  free(log_filebuf);
}
char log_bytebuf[80] = {};
char log_asmbuf[80] = {};

#ifdef CONFIG_ZEBRA_BB_JUMP
#define BB_ADDR_LINE_SIZE 32
const int zebra_bb_addr_line_size = 32;
char* zebra_bb_addr_file_path = NULL;
FILE* zebra_bb_addr_file_fp = NULL;
char zebra_bb_addr_line[BB_ADDR_LINE_SIZE];
char* fgets_ret = NULL;
uint64_t address = 0;

void zebra_bb_jump_init() {
  Assert(zebra_bb_addr_file_path, "zebra_bb_addr_file_path is NULL");
  memset(zebra_bb_addr_line, 0, sizeof(zebra_bb_addr_line));
  zebra_bb_addr_file_fp = fopen(zebra_bb_addr_file_path, "r");
  Assert(zebra_bb_addr_file_fp, "Can not open '%s'", zebra_bb_addr_file_path);
}

#endif