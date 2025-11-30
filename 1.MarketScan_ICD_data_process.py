import os
from pathlib import Path
from collections import defaultdict
import argparse

def process_file(input_path, output_path, li):
    try:
        with open(input_path, 'r') as ceshi, open(output_path, 'w') as file:
            for line in ceshi:
                line = line.strip()
                cols = line.split("^")
                info = cols[0]
                if len(cols) > 1:
                    xz = cols[1].split("|")
                    for i in range(len(xz)):
                        if xz[i].split(":")[0].strip() in li:
                            jibing = ""
                            for item in xz[:i + 1]:
                                item = item + "|"
                                jibing += item
                            file.write(info + "^" + jibing + "\n")
                            break
        print(f"Processed: {input_path} -> {output_path}")
    except Exception as e:
        print(f"Error processing {input_path}: {e}")

def filter_two_years_data(input_path, output_path):
    try:
        with open(input_path, 'r') as csgo, open(output_path, 'w') as csto:
            for i in csgo:
                guiji_2nian = []
                patient = i.strip().split("^")
                cs = patient[0]
                zx = patient[1]
                zc = zx.strip().split('|')
                cv = int(zc[-2].split(":")[2].strip())
                cx = int(zc[0].split(":")[2].strip())
                if cv - cx >= 730:
                    guiji_2nian = cs + "^" + zx
                    csto.write(guiji_2nian + "\n")
        print(f"Filtered 2+ years data: {input_path} -> {output_path}")
    except Exception as e:
        print(f"Error filtering {input_path}: {e}")

def generate_infectious_disease_dict(input_path):
    dic = defaultdict(list)
    try:
        with open(input_path, 'r') as f:
            for line in f:
                line = line.strip()
                cols = line.split(":")
                dic[cols[0]] = cols[1].split(",")
        print("Generated infectious disease dictionary")
    except Exception as e:
        print(f"Error generating dictionary from {input_path}: {e}")
    return dic

def map_cancer_data(input_path, output_path, dic):
    try:
        with open(input_path, 'r') as ceshi, open(output_path, 'w') as ceshiout:
            for i in ceshi:
                patientzu = []
                i = i.strip()
                patient = i.split("^")
                patient_1 = patient[0].split("|")
                patientzu.append(patient_1[0] + ',' + patient_1[1].strip() + '|' + patient_1[3] + '|' + patient_1[5] + '^')
                patient_2 = patient[1].split("|")
                for i1 in patient_2:
                    patient_3 = i1.split(":")
                    for key in dic.keys():
                        if len(patient_3) > 2:
                            if patient_3[0].strip() in dic[key]:
                                patientzu.append(key + ',' + patient_3[1].strip() + ',' + patient_3[2].strip() + '|')
                                break
                ceshiout.write("".join(patientzu) + '\n')
        print(f"Mapped cancer data: {input_path} -> {output_path}")
    except Exception as e:
        print(f"Error mapping cancer data from {input_path}: {e}")

def filter_mapped_data(input_path, output_path):
    try:
        with open(input_path, 'r') as ceshiout, open(output_path, 'w') as ceshi:
            for i in ceshiout:
                patientzu = []
                i = i.strip()
                patient = i.split("^")
                patient_1 = patient[0]
                patient_2 = patient[1]
                patient_3 = patient_2.strip().split("|")
                if len(patient_3) > 2:
                    patientzu.append(patient_1 + "^" + patient_2)
                ceshi.write("".join(patientzu))
        print(f"Filtered mapped data: {input_path} -> {output_path}")
    except Exception as e:
        print(f"Error filtering mapped data from {input_path}: {e}")

def main(input_directory, output_directory, disease_dict_path):
    li = ['230.1', '150.9', '150.8', '150.5', '150.4', '150.1', '150.0', '150.3', '150.2', 'D00.1', 'C15.9', 'C15.8', 'C15.5', 'C15.4', 'C15.3']
    
    # Ensure the output directory exists.
    if not os.path.exists(output_directory):
        os.makedirs(output_directory)

    # Generate infectious disease dictionary.
    dic = generate_infectious_disease_dict(disease_dict_path)

    # Iterate through all files in the input directory.
    for root, _, files in os.walk(input_directory):
        for file_name in files:
            input_path = os.path.join(root, file_name)
            output_path_extracted = os.path.join(output_directory, f"processed_{file_name}")
            output_path_filtered = os.path.join(output_directory, f"filtered_{file_name}")
            output_path_mapped = os.path.join(output_directory, f"mapped_{file_name}")
            output_path_final_filtered = os.path.join(output_directory, f"final_filtered_{file_name}")
            
            # Process the files to extract data containing the specified ICD codes.
            process_file(input_path, output_path_extracted, li)
            
            # Filter out data exceeding 2 years.
            filter_two_years_data(output_path_extracted, output_path_filtered)
            
            # Map the infectious disease data.
            map_cancer_data(output_path_filtered, output_path_mapped, dic)
            
            # Filter data containing only cancer cases.
            filter_mapped_data(output_path_mapped, output_path_final_filtered)

def main(input_directory, output_directory, disease_dict_path):

    pass

if __name__ == "__main__":
    # Use argparse to get input arguments.
    parser = argparse.ArgumentParser(description="Process infectious disease data and save results.")
    parser.add_argument("--input_file", type=str, required=True, help="The input file containing infectious disease data (e.g., 'test data.txt').")
    parser.add_argument("--output_directory", type=str, required=True, help="The directory to save the output files.")
    parser.add_argument("--disease_dict_path", type=str, required=True, help="The file path of the disease dictionary (e.g., 'Disease and Corresponding ICD-9 and ICD-10 Codes.txt').")
    args = parser.parse_args()
    
    # Ensure the path exists.
    input_directory = Path(args.input_directory).resolve()
    output_directory = Path(args.output_directory).resolve()
    disease_dict_path = Path(args.disease_dict_path).resolve()

    if not input_directory.exists():
        raise FileNotFoundError(f"Input directory does not exist: {input_directory}")
    if not output_directory.exists():
        os.makedirs(output_directory)  # If the output directory does not exist, create it automatically.
    if not disease_dict_path.exists():
        raise FileNotFoundError(f"Disease dictionary file does not exist: {disease_dict_path}")

    main(input_directory, output_directory, disease_dict_path)


'''
输入数据：
	•	一批原始病历轨迹文件（例如每个文件包含病人的疾病发生顺序及时间）。
	•	一个“感染性疾病与癌症对应字典”（Disease and Corresponding ICD-9 and ICD-10 Codes.txt）。

主要目标：
	1.	找出病人中包含某些特定癌症 ICD 编码的病例（例如食管癌等）。
	2.	筛选出病程至少 2 年的个体。
	3.	将这些病程轨迹中的感染性疾病映射到标准癌症分类字典。
	4.	输出处理后的结构化文件，方便后续疾病进展分析（例如：感染 → 癌症）。
'''