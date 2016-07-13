#include "curve_2d.h"
#include <assert.h>
#include <list>

template<class T>
static inline T _bezier_interp(real_t t, T start, T control_1, T control_2, T end) {
    /* Formula from Wikipedia article on Bezier curves. */
	real_t omt =(1.0 - t);
	real_t omt2 = omt*omt;
	real_t omt3 = omt2*omt;
	real_t t2 = t*t;
	real_t t3 = t2*t;

	return start * omt3
	   + control_1 * omt2 * t * 3.0
	   + control_2 * omt  * t2 * 3.0
	   + end * t3;
}


static inline double deg2rad(double p_y) {

	return p_y*Math_PI/180.0;
}

static inline double rad2deg(double p_y) {

	return p_y*180.0/Math_PI;
}

int Curve2D::get_point_count() const {

	return points.size();
}

void Curve2D::add_point(const Vector2& p_pos, const Vector2& p_in, const Vector2& p_out,int p_atpos) {

	Point n;
	n.pos=p_pos;
	n.in=p_in;
	n.out=p_out;
	if(p_atpos>=0 && p_atpos<points.size())
		points.insert(points.begin() + p_atpos,n);
	else
		points.push_back(n);

	baked_cache_dirty = true;
}

void Curve2D::set_point_pos(int p_index, const Vector2& p_pos) {

	assert(p_index < points.size());
	points[p_index].pos=p_pos;
	baked_cache_dirty=true;
}

Vector2 Curve2D::get_point_pos(int p_index) const {

	assert(p_index < points.size());
	return points[p_index].pos;
}

void Curve2D::set_point_in(int p_index, const Vector2& p_in) {

	assert(p_index < points.size());
	points[p_index].in=p_in;
	baked_cache_dirty=true;
}

Vector2 Curve2D::get_point_in(int p_index) const {

	assert(p_index < points.size());
	return points[p_index].in;
}

void Curve2D::set_point_out(int p_index, const Vector2& p_out) {

	assert(p_index < points.size());
	points[p_index].out=p_out;
	baked_cache_dirty=true;
}

Vector2 Curve2D::get_point_out(int p_index) const {

	assert(p_index < points.size());
	return points[p_index].out;
}

void Curve2D::remove_point(int p_index) {

	assert(p_index < points.size());
	points.erase(points.begin() + p_index);
	baked_cache_dirty=true;
}

Vector2 Curve2D::interpolate(int p_index, float p_offset) const {

	int pc = points.size();
	if(pc == 0)
		return Vector2();

	if(p_index >= pc-1)
		return points[pc-1].pos;
	else if(p_index<0)
		return points[0].pos;

	Vector2 p0 = points[p_index].pos;
	Vector2 p1 = p0 + points[p_index].out;
	Vector2 p3 = points[p_index+1].pos;
	Vector2 p2 = p3 + points[p_index+1].in;

	return _bezier_interp(p_offset, p0, p1, p2, p3);
}

Vector2 Curve2D::interpolatef(real_t p_findex) const {

	if(p_findex < 0)
		p_findex = 0;
	else if(p_findex >= points.size())
		p_findex=points.size();

	return interpolate((int)p_findex, fmod(p_findex, 1.0));
}

void Curve2D::_bake_segment2d(
	std::map<float, Vector2>& r_bake, float p_begin,
	float p_end,
	const Vector2& p_a,
	const Vector2& p_out,
	const Vector2& p_b,
	const Vector2& p_in,
	int p_depth,
	int p_max_depth,
	float p_tol
) const {

	float mp = p_begin + (p_end - p_begin) * 0.5;
	Vector2 beg = _bezier_interp(p_begin, p_a, p_a + p_out, p_b + p_in, p_b);
	Vector2 mid = _bezier_interp(mp, p_a, p_a + p_out, p_b + p_in, p_b);
	Vector2 end = _bezier_interp(p_end, p_a, p_a + p_out, p_b + p_in, p_b);

	Vector2 na =(mid - beg).normalized();
	Vector2 nb =(end - mid).normalized();
	float dp = na.dot(nb);

	if(dp < cos(deg2rad(p_tol))) {
		r_bake[mp]=mid;
	}

	if(p_depth<p_max_depth) {
		_bake_segment2d(r_bake, p_begin, mp, p_a, p_out, p_b, p_in, p_depth + 1, p_max_depth, p_tol);
		_bake_segment2d(r_bake, mp, p_end, p_a, p_out, p_b, p_in, p_depth + 1, p_max_depth, p_tol);
	}
}

void Curve2D::_bake() const {

	if(!baked_cache_dirty)
		return;

	baked_max_ofs = 0;
	baked_cache_dirty = false;

	if(points.size() == 0) {
		baked_point_cache.resize(0);
		return;
	}

	if(points.size()==1) {

		baked_point_cache.resize(1);
		baked_point_cache[0] = points[0].pos;
		return;
	}

	Vector2 pos=points[0].pos;
	std::list<Vector2> pointlist;

	pointlist.push_back(pos); //start always from origin

	for(int i=0;i<points.size()-1;i++) {

		float step = 0.1; // at least 10 substeps ought to be enough?
		float p = 0;

		while(p<1.0) {

			float np=p+step;
			if(np>1.0)
				np=1.0;


			Vector2 npp = _bezier_interp(np, points[i].pos,points[i].pos+points[i].out,points[i+1].pos+points[i+1].in,points[i+1].pos);
			float d = pos.distance_to(npp);

			if(d>bake_interval) {
				// OK! between P and NP there _has_ to be Something, let's go searching!

				int iterations = 10; //lots of detail!

				float low = p;
				float hi = np;
				float mid = low+(hi-low)*0.5;

				for(int j=0;j<iterations;j++) {


					npp = _bezier_interp(mid, points[i].pos,points[i].pos+points[i].out,points[i+1].pos+points[i+1].in,points[i+1].pos);
					d = pos.distance_to(npp);

					if(bake_interval < d)
						hi=mid;
					else
						low=mid;
					mid = low+(hi-low)*0.5;

				}

				pos=npp;
				p=mid;
				pointlist.push_back(pos);
			} else {

				p=np;
			}

		}
	}

	Vector2 lastpos = points[points.size()-1].pos;

	float rem = pos.distance_to(lastpos);
	baked_max_ofs=(pointlist.size()-1)*bake_interval+rem;
	pointlist.push_back(lastpos);

	baked_point_cache.resize(pointlist.size());
	int idx=0;

	for(std::list<Vector2>::const_iterator itr = pointlist.begin(); itr != pointlist.end(); ++itr) {

		baked_point_cache[idx] = *itr;
		idx++;
	}
}

float Curve2D::get_baked_length() const {

	if(baked_cache_dirty)
		_bake();
	return baked_max_ofs;
}

Vector2 Curve2D::interpolate_baked(float p_offset,bool p_cubic) const{

	if(baked_cache_dirty)
		_bake();

	//validate//
	int pc = baked_point_cache.size();
	if(pc==0) {
// 		ERR_EXPLAIN("No points in Curve2D");
		return Vector2();
	}

	if(pc==1)
		return baked_point_cache[0];

	int bpc=baked_point_cache.size();

	if(p_offset<0)
		return baked_point_cache[0];
	if(p_offset>=baked_max_ofs)
		return baked_point_cache[bpc-1];

	int idx = floor(p_offset/bake_interval);
	float frac = fmod(p_offset,bake_interval);

	if(idx>=bpc-1) {
		return baked_point_cache[bpc-1];
	} else if(idx==bpc-2) {
		frac/=fmod(baked_max_ofs,bake_interval);
	} else {
		frac/=bake_interval;
	}

	if(p_cubic) {

		Vector2 pre = idx>0? baked_point_cache[idx-1] : baked_point_cache[idx];
		Vector2 post =(idx<(bpc-2))? baked_point_cache[idx+2] : baked_point_cache[idx+1];
		return baked_point_cache[idx].cubic_interpolate(baked_point_cache[idx+1],pre,post,frac);
	} else {
		return baked_point_cache[idx].linear_interpolate(baked_point_cache[idx+1],frac);
	}
}

Vector2Array Curve2D::get_baked_points() const {

	if(baked_cache_dirty)
		_bake();

	return baked_point_cache;
}

void Curve2D::set_bake_interval(float p_tolerance){

	bake_interval=p_tolerance;
	baked_cache_dirty=true;
}

float Curve2D::get_bake_interval() const{

	return bake_interval;
}

Vector2Array Curve2D::tesselate(int p_max_stages,float p_tolerance) const {

	Vector2Array tess;

	if(points.size()==0) {
		return tess;
	}
	std::vector< std::map<float,Vector2> > midpoints;

	midpoints.resize(points.size()-1);

	int pc=1;
	for(int i=0;i<points.size()-1;i++) {

		_bake_segment2d(midpoints[i],0,1,points[i].pos,points[i].out,points[i+1].pos,points[i+1].in,0,p_max_stages,p_tolerance);
		pc++;
		pc+=midpoints[i].size();

	}

	tess.resize(pc);
	tess[0]=points[0].pos;
	int pidx=0;

	for(int i=0;i<points.size()-1;i++) {

		for(std::map<float,Vector2>::const_iterator itr = midpoints[i].begin(); itr != midpoints[i].end(); ++itr) {

			pidx++;
			tess[pidx] = itr->second;
		}

		pidx++;
		tess[pidx] = points[i+1].pos;

	}

	return tess;
}

Curve2D::Curve2D() {
	baked_cache_dirty = false;
	baked_max_ofs = 0;
	bake_interval = 5;
}
