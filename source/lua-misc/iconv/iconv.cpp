// TODO: linux icon implement
#include "iconv.h"

#define WIN32_LEARN_AND_MEAN
#include <Windows.h>

#define CP_GBK	936
#define CP_BIG5	950

template<const int in_codepage, const int out_codepage>
static bool convert(const std::string& in, std::string& out) {

	if(in.empty()) {
		out = "";
		return true;
	}

	// calc input length
	int in_len = MultiByteToWideChar(in_codepage, 0, in.c_str(), -1, NULL, 0);
	if(in_len <= 0)
		return false;

	// convert to unicode
	std::wstring u;
	u.resize(in_len);
	MultiByteToWideChar(in_codepage, 0, in.c_str(), -1, &u[0], in_len);

	// convert to output
	int out_len = WideCharToMultiByte(out_codepage, 0, &u[0], -1, NULL, 0, NULL, NULL);
	if(out_len <= 0)
		return false;

	out.resize(out_len);
	WideCharToMultiByte(out_codepage, 0, &u[0], -1, &out[0], out_len, NULL, NULL);

	return true;
}

bool utf2gbk(const std::string& in, std::string& out) {

	return convert<CP_UTF8, CP_GBK>(in, out);
}

bool gbk2utf(const std::string& in, std::string& out) {

	return convert<CP_GBK, CP_UTF8>(in, out);
}

bool utf2big(const std::string& in, std::string& out) {

	return convert<CP_UTF8, CP_BIG5>(in, out);
}

bool big2utf(const std::string& in, std::string& out) {

	return convert<CP_BIG5, CP_UTF8>(in, out);
}

bool big2gbk(const std::string& in, std::string& out) {

	return convert<CP_BIG5, CP_GBK>(in, out);
}

bool gbk2big(const std::string& in, std::string& out) {

	return convert<CP_GBK, CP_BIG5>(in, out);
}
