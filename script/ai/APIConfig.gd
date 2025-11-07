# APIConfig.gd - API配置管理器
# 统一管理所有API相关的配置信息，避免硬编码和重复代码

class_name APIConfig

# API类型枚举
enum APIType {
	OLLAMA,
	OPENAI,
	DEEPSEEK,
	DOUBAO,
	GEMINI,
	CLAUDE,
	SILICONFLOW,
	KIMI,
	OPENAI_COMPATIBLE  # 新增：OpenAI兼容API枚举
}

# API配置数据结构
class APIProvider:
	var name: String
	var display_name: String
	var url: String
	var models: Array[String]
	var requires_api_key: bool
	var headers_template: Dictionary
	var request_format: String  # "ollama", "openai", "gemini", "claude"
	var response_parser: String  # 响应解析器类型
	
	func _init(n: String, dn: String, u: String, m: Array[String], req_key: bool, headers: Dictionary, req_fmt: String, resp_parser: String):
		name = n
		display_name = dn
		url = u
		models = m
		requires_api_key = req_key
		headers_template = headers
		request_format = req_fmt
		response_parser = resp_parser

# 静态配置数据
static var _providers: Dictionary = {}
static var _initialized: bool = false

# 初始化API提供商配置
static func _initialize():
	if _initialized:
		return
	
	# Ollama配置
	_providers["Ollama"] = APIProvider.new(
		"Ollama",
		"Ollama (本地)",
		"http://localhost:11434/api/generate",
		["qwen2.5:1.5b", "llama3.2:1b", "llama3.2:3b", "gemma2:2b"],
		false,
		{"Content-Type": "application/json"},
		"ollama",
		"ollama"
	)
	
	# OpenAI配置
	_providers["OpenAI"] = APIProvider.new(
		"OpenAI",
		"OpenAI",
		"https://api.openai.com/v1/chat/completions",
		["gpt-4o-mini", "gpt-4o", "gpt-3.5-turbo"],
		true,
		{"Content-Type": "application/json", "Authorization": "Bearer {api_key}"},
		"openai",
		"openai"
	)
	
	# DeepSeek配置
	_providers["DeepSeek"] = APIProvider.new(
		"DeepSeek",
		"DeepSeek",
		"https://api.deepseek.com/v1/chat/completions",
		["deepseek-chat"],
		true,
		{"Content-Type": "application/json", "Authorization": "Bearer {api_key}"},
		"openai",
		"openai"
	)
	
	# 豆包配置
	_providers["Doubao"] = APIProvider.new(
		"Doubao",
		"豆包 (字节跳动)",
		"https://ark.cn-beijing.volces.com/api/v3/chat/completions",
		["doubao-lite-4k", "doubao-lite-32k", "doubao-lite-128k", "doubao-pro-4k", "doubao-pro-32k", "doubao-pro-128k"],
		true,
		{"Content-Type": "application/json", "Authorization": "Bearer {api_key}"},
		"openai",
		"openai"
	)
	
	# Gemini配置
	_providers["Gemini"] = APIProvider.new(
		"Gemini",
		"Gemini (Google)",
		"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent",
		["gemini-1.5-flash", "gemini-1.5-pro", "gemini-1.0-pro"],
		true,
		{"Content-Type": "application/json", "x-goog-api-key": "{api_key}"},
		"gemini",
		"gemini"
	)
	
	# Claude配置
	_providers["Claude"] = APIProvider.new(
		"Claude",
		"Claude (Anthropic)",
		"https://api.anthropic.com/v1/messages",
		["claude-3-5-sonnet-20241022", "claude-3-5-haiku-20241022", "claude-3-opus-20240229"],
		true,
		{"Content-Type": "application/json", "Authorization": "Bearer {api_key}", "anthropic-version": "2023-06-01"},
		"claude",
		"claude"
	)
	
	# KIMI配置
	_providers["KIMI"] = APIProvider.new(
		"KIMI",
		"KIMI (月之暗面)",
		"https://api.moonshot.cn/v1/chat/completions",
		["moonshot-v1-8k", "moonshot-v1-32k", "moonshot-v1-128k"],
		true,
		{"Content-Type": "application/json", "Authorization": "Bearer {api_key}"},
		"openai",
		"openai"
	)


	# 硅基流动配置
	_providers["SiliconFlow"] = APIProvider.new(
		"SiliconFlow",
		"硅基流动",
		"https://api.siliconflow.cn/v1/chat/completions",
		["deepseek-ai/DeepSeek-V3.1-Terminus", "inclusionAI/Ring-1T", "zai-org/GLM-4.6"],
		true,
		{"Content-Type": "application/json", "Authorization": "Bearer {api_key}"},
		"openai",
		"openai"
	)
	
# 新增：OpenAI Compatible通用提供商
	# URL 这里用占位符，在运行时替换或通过配置文件设置
	_providers["OpenAICompatible"] = APIProvider.new(
		"OpenAICompatible",
		"OpenAI Compatible (自定义)",
		"https://custom-openai-compatible.com/v1/chat/completions",  # 占位符URL，实际使用时可扩展动态设置
		[],  # 模型列表为空，由用户指定或动态加载
		true,
		{"Content-Type": "application/json", "Authorization": "Bearer {api_key}"},
		"openai",
		"openai"
	)
	
	_initialized = true

# 获取所有API提供商名称（自动包含新增）
static func get_api_types() -> Array[String]:
	_initialize()
	var result: Array[String] = []
	for key in _providers.keys():
		result.append(key)
	return result

# 获取API提供商配置
static func get_provider(api_type: String) -> APIProvider:
	_initialize()
	return _providers.get(api_type, _providers["Ollama"])

# 获取指定API的模型列表
static func get_models_for_api(api_type: String) -> Array[String]:
	_initialize()
	var provider = get_provider(api_type)
	return provider.models

# 检查API是否需要密钥
static func requires_api_key(api_type: String) -> bool:
	_initialize()
	var provider = get_provider(api_type)
	return provider.requires_api_key

# 构建请求数据
static func build_request_data(api_type: String, model: String, prompt: String) -> Dictionary:
	_initialize()
	var provider = get_provider(api_type)
	
	match provider.request_format:
		"ollama":
			return {
				"model": model,
				"prompt": prompt,
				"stream": false
			}
		"openai":
			return {
				"model": model,
				"messages": [{
					"role": "user",
					"content": prompt
				}]
			}
		"gemini":
			return {
				"contents": [{
					"parts": [{
						"text": prompt
					}]
				}]
			}
		"claude":
			return {
				"model": model,
				"max_tokens": 1024,
				"messages": [{
					"role": "user",
					"content": prompt
				}]
			}
		_:
			return {}

# 构建请求头
static func build_headers(api_type: String, api_key: String) -> Array[String]:
	_initialize()
	var provider = get_provider(api_type)
	var headers: Array[String] = []
	
	for key in provider.headers_template:
		var value = provider.headers_template[key]
		if value.find("{api_key}") != -1:
			value = value.replace("{api_key}", api_key)
		headers.append(key + ": " + value)
	
	return headers

# 获取请求URL（新增对兼容模式的处理，如果需要动态URL，可在这里扩展）
static func get_url(api_type: String, model: String = "") -> String:
	_initialize()
	var provider = get_provider(api_type)
	var url = provider.url
	
	if url.find("{model}") != -1:
		url = url.replace("{model}", model)
	
	# 新增：如果api_type是OpenAICompatible，可以添加自定义逻辑（如从全局配置读取URL）
	# if api_type == "OpenAICompatible":
	#     url = GlobalConfig.custom_openai_url  # 示例扩展，需项目支持
	 
	return url

# 解析API响应
static func parse_response(api_type: String, response: Dictionary, character_name: String = "") -> String:
	_initialize()
	var provider = get_provider(api_type)
	
	match provider.response_parser:
		"ollama":
			if not "response" in response:
				print("[APIConfig] %s 的Ollama API响应格式错误：缺少response字段" % character_name)
				return ""
			return response.response
		
		"openai":
			if not "choices" in response or not response.has("choices") or response.choices.size() == 0:
				print("[APIConfig] %s 的OpenAI格式API响应错误：缺少choices字段或为空" % character_name)
				return ""
			if not response.choices[0].has("message") or not response.choices[0].message.has("content"):
				print("[APIConfig] %s 的OpenAI格式API响应错误：缺少message或content字段" % character_name)
				return ""
			return response.choices[0].message.content
		
		"gemini":
			if not "candidates" in response or response.candidates.size() == 0:
				print("[APIConfig] %s 的Gemini API响应格式错误：缺少candidates字段或为空" % character_name)
				return ""
			if not response.candidates[0].has("content") or not response.candidates[0].content.has("parts") or response.candidates[0].content.parts.size() == 0:
				print("[APIConfig] %s 的Gemini API响应格式错误：缺少content或parts字段" % character_name)
				return ""
			return response.candidates[0].content.parts[0].text
		
		"claude":
			if not "content" in response or response.content.size() == 0:
				print("[APIConfig] %s 的Claude API响应格式错误：缺少content字段或为空" % character_name)
				return ""
			if not response.content[0].has("text"):
				print("[APIConfig] %s 的Claude API响应格式错误：缺少text字段" % character_name)
				return ""
			return response.content[0].text
		
		_:
			print("[APIConfig] %s 未知的API类型，使用默认处理" % character_name)
			return ""
