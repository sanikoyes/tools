#include "../typedef.h"
#include <math.h>
#include <vector>
#include <map>

typedef struct Vector2 {
	real_t x, y;
	Vector2() : x(0), y(0) {}
	Vector2(const real_t& p_x, const real_t& p_y)
		: x(p_x)
		, y(p_y)
	{}

	Vector2 operator + (const Vector2& p_v) const { return Vector2(x + p_v.x, y + p_v.y); }
	Vector2 operator - (const Vector2& p_v) const { return Vector2(x - p_v.x, y - p_v.y); }

	Vector2 operator * (const real_t& p_v) const { return Vector2(x * p_v, y * p_v); }
	Vector2 operator * (const Vector2& p_v) const { return Vector2(x * p_v.x, y * p_v.y); }

	void operator += (const Vector2 &rvalue) { x += rvalue.x; y += rvalue.y; }
	void operator -= (const Vector2& p_v) { this->x -= p_v.x; this->y -= p_v.y; }

	void operator *= (const real_t &p_v) { x *= p_v; y *= p_v; }
	void operator *= (const Vector2 &rvalue) { x *= rvalue.x; y *= rvalue.y; }

	Vector2 operator-() const { return Vector2(-x, -y); }

	float dot(const Vector2& p_other) const {
		return x * p_other.x + y * p_other.y;
	}

	void normalize() {
		float l = x * x + y * y;
		if(l != 0) {

			l = sqrt(l);
			x /= l;
			y /= l;
		}
	}

	Vector2 normalized() const {
		Vector2 v=*this;
		v.normalize();
		return v;
	}

	inline float distance_to(const Vector2& p_vector2) const {

		return sqrt( (x-p_vector2.x)*(x-p_vector2.x) + (y-p_vector2.y)*(y-p_vector2.y));
	}

	Vector2 linear_interpolate(const Vector2& p_b,float p_t) const {

		Vector2 res=*this;

		res.x+= (p_t * (p_b.x-x));
		res.y+= (p_t * (p_b.y-y));

		return res;
	}

	Vector2 cubic_interpolate(const Vector2& p_b,const Vector2& p_pre_a, const Vector2& p_post_b,float p_t) const {

		Vector2 p0=p_pre_a;
		Vector2 p1=*this;
		Vector2 p2=p_b;
		Vector2 p3=p_post_b;

		float t = p_t;
		float t2 = t * t;
		float t3 = t2 * t;

		Vector2 out;
		out = ( ( p1 * 2.0f) +
		( -p0 + p2 ) * t +
		( p0 * 2.0f - p1 * 5.0f + p2 * 4 - p3 ) * t2 +
		( -p0 + p1 * 3.0f - p2 * 3.0f + p3 ) * t3 ) * 0.5f;
		return out;
	}

} Vector2;

typedef std::vector<Vector2> Vector2Array;

class Curve2D {

	struct Point {
		Vector2 in;
		Vector2 out;
		Vector2 pos;

		Point() {}
	};

	std::vector<Point> points;

	struct BakedPoint {

		float ofs;
		Vector2 point;
	};

	mutable bool baked_cache_dirty;
	mutable Vector2Array baked_point_cache;
	mutable float baked_max_ofs;

	float bake_interval;

	void _bake() const;
	void _bake_segment2d(std::map<float,Vector2>& r_bake, float p_begin, float p_end,const Vector2& p_a,const Vector2& p_out,const Vector2& p_b, const Vector2& p_in,int p_depth,int p_max_depth,float p_tol) const;
// 	Dictionary _get_data() const;
// 	void _set_data(const Dictionary &p_data);

protected:

public:
	int get_point_count() const;
	void add_point(const Vector2& p_pos, const Vector2& p_in=Vector2(), const Vector2& p_out=Vector2(),int p_atpos=-1);
	void set_point_pos(int p_index, const Vector2& p_pos);
	Vector2 get_point_pos(int p_index) const;
	void set_point_in(int p_index, const Vector2& p_in);
	Vector2 get_point_in(int p_index) const;
	void set_point_out(int p_index, const Vector2& p_out);
	Vector2 get_point_out(int p_index) const;
	void remove_point(int p_index);

	Vector2 interpolate(int p_index, float p_offset) const;
	Vector2 interpolatef(real_t p_findex) const;

	void set_bake_interval(float p_distance);
	float get_bake_interval() const;

	float get_baked_length() const;
	Vector2 interpolate_baked(float p_offset,bool p_cubic=false) const;
	Vector2Array get_baked_points() const; //useful for going thru

	Vector2Array tesselate(int p_max_stages=5,float p_tolerance=4) const; //useful for display

	Curve2D();
};
