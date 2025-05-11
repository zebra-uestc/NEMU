#!/bin/env python3
import os
import re

import meta


def read_bb_inst_count(file_path):
    """
    read_bb_inst_count 函数用于从指定文件中读取基本块指令信息。
    该函数会逐行读取文件内容，使用正则表达式匹配基本块的相关信息，
    并将匹配到的信息以字典的形式存储在列表中返回。

    :param file_path: 包含基本块指令信息的文件路径
    :return: 存储基本块信息的列表，每个元素是一个字典，包含 'id', 'insts', 'start', 'end' 四个键
    """
    # 初始化一个空列表，用于存储读取到的基本块信息
    data = []
    # 定义正则表达式模式，用于匹配文件中每行的基本块信息
    # 匹配格式为 "id: 数字 insts: 数字 address: [起始地址 -> 结束地址]"
    pattern = r"id: (\d+)\s+insts: (\d+)\s+address:\s+\[(.+) -> (.+)\]"
    # 以只读模式打开指定文件
    with open(file_path, "r") as file:
        # 逐行读取文件内容
        for line in file:
            # 去除每行首尾的空白字符
            line = line.strip()
            # 使用正则表达式在当前行中查找匹配项
            match = re.search(pattern, line)
            # 如果找到匹配项
            if match:
                # 提取匹配到的基本块 ID，并转换为整数类型
                bbv_id = int(match.group(1))
                # 提取匹配到的指令数量，并转换为整数类型
                insts = int(match.group(2))
                # 提取匹配到的起始地址，并去除首尾空白字符
                start = match.group(3).strip()
                # 提取匹配到的结束地址，并去除首尾空白字符
                end = match.group(4).strip()
                # 将提取到的信息以字典形式添加到列表中
                data.append({"id": bbv_id, "insts": insts, "start": start, "end": end})
    return data


def gen_bb_addr_start(benchmark):
    bb_inst_count_path_a = f"/root/NEMU/zebra_data/{benchmark}/bb_inst_count_a.txt"
    bb_inst_count_path_b = f"/root/NEMU/zebra_data/{benchmark}/bb_inst_count_b.txt"
    bb_inst_count_data_a = read_bb_inst_count(bb_inst_count_path_a)
    bb_inst_count_data_b = read_bb_inst_count(bb_inst_count_path_b)
    print(f"bb_inst_count_data_a size: {len(bb_inst_count_data_a)}")
    print(f"bb_inst_count_data_b size: {len(bb_inst_count_data_b)}")

    set_a, set_b = set(), set()
    for i in range(len(bb_inst_count_data_a)):
        set_a.add((bb_inst_count_data_a[i]["start"], bb_inst_count_data_a[i]["end"]))
    for i in range(len(bb_inst_count_data_b)):
        set_b.add((bb_inst_count_data_b[i]["start"], bb_inst_count_data_b[i]["end"]))
    print(f"set_a size: {len(set_a)}")
    print(f"set_b size: {len(set_b)}")

    a_sub_b = set_a - set_b
    b_sub_a = set_b - set_a
    a_intersect_b = set_a & set_b
    print(f"a_sub_b size: {len(a_sub_b)}")
    print(f"b_sub_a size: {len(b_sub_a)}")
    print(f"a_intersect_b size: {len(a_intersect_b)}")

    print("========================")
    print("==> a_sub_b <==")
    for item in a_sub_b:
        print(f"a_sub_b: {item}")
    print("==> b_sub_a <==")
    for item in b_sub_a:
        print(f"b_sub_a: {item}")

    result_file = f"/root/NEMU/zebra_data/{benchmark}/bb_addr_start.txt"
    os.makedirs(os.path.dirname(result_file), exist_ok=True)

    with open(result_file, "w") as file:
        for i in range(len(bb_inst_count_data_a)):
            item = (bb_inst_count_data_a[i]["start"], bb_inst_count_data_a[i]["end"])
            if item in a_intersect_b:
                file.write(f"{item[0]}\n")


if __name__ == "__main__":
    benchmark = meta.benchmarks[2]
    gen_bb_addr_start(benchmark)
