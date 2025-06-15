#!/usr/bin/env python3
"""
IOPaint API测试脚本
用于验证IOPaint服务是否正常运行
"""

import requests
import base64
import json
import sys
from io import BytesIO
from PIL import Image, ImageDraw
import argparse

class IOPaintTester:
    def __init__(self, base_url="http://localhost:8080"):
        self.base_url = base_url
        self.api_base = f"{base_url}/api/v1"
    
    def test_server_health(self):
        """测试服务器是否可访问"""
        try:
            response = requests.get(f"{self.api_base}/server-config", timeout=10)
            if response.status_code == 200:
                print("✅ 服务器连接正常")
                config = response.json()
                print(f"   - 可用模型数量: {len(config.get('modelInfos', []))}")
                print(f"   - 启用文件管理器: {config.get('enableFileManager', False)}")
                print(f"   - 启用自动保存: {config.get('enableAutoSaving', False)}")
                return True
            else:
                print(f"❌ 服务器响应错误: {response.status_code}")
                return False
        except requests.exceptions.RequestException as e:
            print(f"❌ 无法连接到服务器: {e}")
            return False
    
    def create_test_image(self, width=256, height=256):
        """创建测试图像"""
        # 创建一个简单的测试图像
        image = Image.new('RGB', (width, height), color='lightblue')
        draw = ImageDraw.Draw(image)
        
        # 绘制一些图形
        draw.rectangle([50, 50, 150, 150], fill='red', outline='black', width=2)
        draw.ellipse([100, 100, 200, 200], fill='yellow', outline='black', width=2)
        draw.text((10, 10), "Test Image", fill='black')
        
        return image
    
    def create_test_mask(self, width=256, height=256):
        """创建测试蒙版"""
        # 创建蒙版 - 白色区域将被修复
        mask = Image.new('L', (width, height), color='black')
        draw = ImageDraw.Draw(mask)
        
        # 在中心创建一个白色圆形区域
        draw.ellipse([100, 100, 156, 156], fill='white')
        
        return mask
    
    def image_to_base64(self, image):
        """将PIL图像转换为base64字符串"""
        buffer = BytesIO()
        image.save(buffer, format='PNG')
        return base64.b64encode(buffer.getvalue()).decode('utf-8')
    
    def test_inpaint_api(self):
        """测试图像修复API"""
        print("\n🧪 测试图像修复API...")
        
        # 创建测试图像和蒙版
        test_image = self.create_test_image()
        test_mask = self.create_test_mask()
        
        # 转换为base64
        image_b64 = self.image_to_base64(test_image)
        mask_b64 = self.image_to_base64(test_mask)
        
        # 构建请求数据
        request_data = {
            "image": image_b64,
            "mask": mask_b64,
            "ldm_steps": 10,  # 使用较少步数以加快测试
            "ldm_sampler": "plms",
            "hd_strategy": "CROP",
            "prompt": "",
            "negative_prompt": "",
            "sd_seed": 42
        }
        
        try:
            print("   发送修复请求...")
            response = requests.post(
                f"{self.api_base}/inpaint",
                json=request_data,
                headers={"Content-Type": "application/json"},
                timeout=60  # 修复可能需要较长时间
            )
            
            if response.status_code == 200:
                print("✅ 图像修复成功")
                
                # 保存结果图像
                result_image = Image.open(BytesIO(response.content))
                result_image.save("test_result.png")
                print("   - 结果已保存为 test_result.png")
                
                # 检查响应头中的种子值
                seed = response.headers.get('X-Seed')
                if seed:
                    print(f"   - 使用的种子值: {seed}")
                
                return True
            else:
                print(f"❌ 修复失败: {response.status_code}")
                print(f"   错误信息: {response.text}")
                return False
                
        except requests.exceptions.RequestException as e:
            print(f"❌ 请求失败: {e}")
            return False
    
    def test_model_switch(self):
        """测试模型切换"""
        print("\n🔄 测试模型切换...")
        
        try:
            # 获取当前模型
            response = requests.get(f"{self.api_base}/model")
            if response.status_code == 200:
                current_model = response.json()
                print(f"   当前模型: {current_model.get('name', 'unknown')}")
                return True
            else:
                print(f"❌ 获取当前模型失败: {response.status_code}")
                return False
                
        except requests.exceptions.RequestException as e:
            print(f"❌ 请求失败: {e}")
            return False
    
    def run_all_tests(self):
        """运行所有测试"""
        print("🚀 开始IOPaint API测试\n")
        
        tests = [
            ("服务器健康检查", self.test_server_health),
            ("图像修复API", self.test_inpaint_api),
            ("模型信息", self.test_model_switch),
        ]
        
        passed = 0
        total = len(tests)
        
        for test_name, test_func in tests:
            print(f"\n📋 {test_name}")
            print("-" * 40)
            if test_func():
                passed += 1
            else:
                print(f"   测试失败: {test_name}")
        
        print(f"\n📊 测试结果: {passed}/{total} 通过")
        
        if passed == total:
            print("🎉 所有测试通过！IOPaint服务运行正常。")
            return True
        else:
            print("⚠️  部分测试失败，请检查服务配置。")
            return False

def main():
    parser = argparse.ArgumentParser(description="IOPaint API测试工具")
    parser.add_argument(
        "--url", 
        default="http://localhost:8080",
        help="IOPaint服务地址 (默认: http://localhost:8080)"
    )
    parser.add_argument(
        "--test",
        choices=["health", "inpaint", "model", "all"],
        default="all",
        help="要运行的测试类型 (默认: all)"
    )
    
    args = parser.parse_args()
    
    tester = IOPaintTester(args.url)
    
    if args.test == "health":
        success = tester.test_server_health()
    elif args.test == "inpaint":
        success = tester.test_inpaint_api()
    elif args.test == "model":
        success = tester.test_model_switch()
    else:
        success = tester.run_all_tests()
    
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
