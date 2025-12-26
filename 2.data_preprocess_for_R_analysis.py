from pathlib import Path
import argparse

'''
从一个以 "^" 和 "|" 分隔的病人轨迹文件中，提取每个病人的疾病名称，并把它们拼接在一起，用 "-" 连接；然后把原始行中 "/" 之后的部分追加到这一行后面，写入新的输出文件。
'''


def process_files(input_path, output_path):

    with input_path.open("r", encoding="utf-8") as file, output_path.open("w", encoding="utf-8") as file3:
        cols = file.readlines()

        for i in cols:
            patient = i.strip("\n").split("^")
            count = patient[1].split("|")
            for py in count:
                se = py.split(",")[0]
                if se != "":
                    i1 = se + "-"
                    file3.write(i1)

            pa = i.strip("\n").split("/")
            sta = str(pa[1:])
            file3.write(sta + "\n")



if __name__ == "__main__":
    # Use argparse to get arguments from the command line input.
    parser = argparse.ArgumentParser(description="Process cancer data files.")
    parser.add_argument("--input_path", type=str, required=True, help="Path to the input file.")
    parser.add_argument("--output_path", type=str, required=True, help="Path to the output file.")
    args = parser.parse_args()

    # Convert the input path to a pathlib object.
    input_path = Path(args.input_path).resolve()
    output_path = Path(args.output_path).resolve()

    # Check if the input file exists.
    if not input_path.exists():
        raise FileNotFoundError(f"Input file does not exist: {input_path}")

    # Call the main function to process the file.
    process_files(input_path, output_path)

