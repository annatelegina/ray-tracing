#version 330

#define float2 vec2
#define float3 vec3
#define float4 vec4
#define float4x4 mat4
#define float3x3 mat3
#define EPS_DER 0.000001
#define EPS_HIT 0.0001
#define EPS_DOT 0.0
#define NUM 2
#define NUMO 8
#define REFLECTION_DEP 3
in float2 fragmentTexCoord;

layout(location = 0) out vec4 fragColor;



uniform float3 g_bBoxMin   = float3(-1,-2,-1);
uniform float3 g_bBoxMax   = float3(+1,+2,+1);

uniform float4x4 g_rayMatrix;
uniform int g_fog;
uniform int g_reflection;
uniform float4   g_bgColor = float4(0,0,1,1);
float rid;

vec3 amb; // ambient


struct OBJ
{
    float mat_kd;
    float mat_ks;
    float mat_shiness;
    float reflection;
    vec3 color;
};


/*-------- global array of light sourсes: --------*/
vec3 light_s[NUM] = vec3[NUM](vec3(3.3,5.5,3.4), vec3(-5.7,5.5,3.5)) ;


/*-----------------------------------------------------------

   global array of obj's

-------------------------------------------------------------*/

OBJ objects[NUMO] = OBJ[NUMO](
OBJ(0.0,0.0,0.0,0.0,vec3(0.0,0.0,0.0)),
OBJ(50.1,30.9,5.3,0.0,vec3(0.25,0.05,0.0)), // sphere
OBJ(0.7,3.246,10.4,2.0,vec3(0.0,0.12,0.05)), // ploskost
OBJ(0.7,26.0,10.4,0.0,vec3(1.5,1.0,0.0)), // cube
OBJ(10.0,20.0,2.0,0.0,vec3(0.0,0.1,0.2)), // fractal Cube
OBJ(10.0,20.0,25.0,0.0,vec3(0.12,0.1,0.0)), // fractal Julia
OBJ(20.0,20.0,10.0,0.0,vec3(25.0,0.0,255.0)), // Bublik primitive
OBJ(40.0,10.0,10.0,0.0,vec3(0.01,0.6,0.05)) // Another Fractal
);

struct HIT
{
    bool Ex; 
    vec3 normal; 
    int obj;
};
struct PULL
{
    float dist;
    int obj;
};
struct RAY
{
    vec3 p;
    vec3 d;
};
struct FILL
{
    float shiness;
    float kd;
    float ks;
};

float3 EyeRayDir(float x, float y, float w, float h)
{
	float fov = 3.141592654f/(2.0f); 
  float3 ray_dir;
  
	ray_dir.x = x+0.5f - (w/2.0f);
	ray_dir.y = y+0.5f - (h/2.0f);
	ray_dir.z = -(w)/tan(fov/2.0f);
	
  return normalize(ray_dir);
}


/*------primitives-------*/

float Bublik(vec3 p)
{
  vec3 c = vec3(4.2,0.0,-1.4);
  p  = p - c;
  vec2 t = float2(0.4,0.4);
  vec2 q = vec2(length(p.xz)-t.x-0.2,p.y);
  return length(q)-t.y;
}

float Sur(vec3 p)
{
    return p.y + 1.0;
}

float Sphere(vec3 p)
{
  vec3 c = vec3(2.0,-0.2,-3.0);
  float s = 0.8;
  return length(p-c)-s;
}

float Box( vec3 p)
{
  vec3 c = vec3(0.0,-0.4,0.0);
  p -= c;
  vec3 b = vec3(0.5, 0.5, 0.5);
  return length(max(abs(p)-b,0.0));
}


/*------fractals and help functions------*/

float maxcomp(vec3 p) { return max(p.x,max(p.y,p.z));}
float sdBox(vec3 p)
{
   vec3 b = float3(1.0,1.0,1.0);
  vec3  di = abs(p) - b;
  float mc = maxcomp(di);
  return min(mc,length(max(di,0.0)));
}

float Fractal3 (vec3 p)
{
    vec3 c = vec3(1.0,0.0,3.0);
    p -= c;
    const mat3 ma = mat3( 0.60, 0.00,  0.80,
                      0.00, 1.00,  0.00,
                     -0.80, 0.00,  0.60 );
    float d = sdBox(p);
    float ani = 1.0;
	float off = 0.0;
    float s = 1.0;
    int numIterations = 4;
    for( int m = 0; m < numIterations; m++)
    {   
        vec3 a = mod( p*s, 2.0 )-1.0;
        s *= 3.0;
        vec3 r = abs(1.0 - 3.0*abs(a));
        float da = max(r.x,r.y);
        float db = max(r.y,r.z);
        float dc = max(r.z,r.x);
        float c = (min(da,min(db,dc))-1.0)/s;
        if (c > d)
            d = c;
    }
    return d;
}

vec4 qsqr( vec4 a )
{
    return vec4( a.x*a.x - a.y*a.y - a.z*a.z - a.w*a.w,
                 2.0*a.x*a.y,
                 2.0*a.x*a.z,
                 2.0*a.x*a.w );
}

const int j_Iterations = 11;

float FracJulia(vec3 p)
{
    vec3 c = vec3(3.0,0.0,1.0);
    p -= c;
    vec4 z = vec4(p, 0.0);
    float md2 = 1.0;
    float mz2 = dot(z, z);

    vec4 trap = vec4(abs(z.xyz), mz2);

    for( int i = 0; i < j_Iterations; i++)
    {
        md2 *= 4.0*mz2;
        z = qsqr(z)  + 0.45*cos( vec4(0.5,3.5,1.4,1.1) + 2.5*vec4(1.2,1.7,1.0,2.5) ) - vec4(0.3,0.0,0.0,0.0);
        mz2 = dot(z,z);
        if (mz2 > 4.0)
            break;
    }
    return 0.25*sqrt(mz2/md2)*log(mz2);
}
 
vec2 cmul( vec2 a, vec2 b )  { return vec2( a.x*b.x - a.y*b.y, a.x*b.y + a.y*b.x ); }
vec2 csqr( vec2 a )  { return vec2( a.x*a.x - a.y*a.y, 2.*a.x*a.y  ); }

vec3 dmul( vec3 a, vec3 b )  {
    float r = length(a);
    
    b.xy=cmul(normalize(a.xy), b.xy);
    b.yz=cmul(normalize(a.yz), b.yz);
    b.xz=cmul(normalize(a.xz), b.xz);
    
    return r*b;
}

float AnotherFractal( vec3 p)
{
    vec3 center = vec3(-2.0,0.0,2.0);
    p -= center;
	float dr = 1.0;
	float r2;
    vec3 c = p;
    int Iterations = 5;
	for (int i=0; i < Iterations; i++)
	{            
        r2 = sqrt(dot(p, p));
        if (r2>4.0) 
            continue;
        dr = 2.0*r2*dr + 1.0;
        p = dmul(p, p) + c;						
	}
	float l = length(p);	
	float d =.5*l*log(l)/dr;	
        return d;	
}

PULL Draw(vec3 p)
{
    float D1,D2,D3,D4,D5,D6,D7;
    PULL pull;
    D1 = Sphere(p);
    D2 = Sur(p);
    D3 = Fractal3(p);
    D4 = FracJulia(p);
    D5 = Bublik(p);
    D6 = AnotherFractal(p);
    D7 = Box(p);
    float k = min(min(min(min(min(min(D1,D2), D3), D4), D5), D6), D7);
    pull.dist = k;
    if (k == D1)
    {
        pull.obj = 1;
    }
    else 
    if (k == D2)
    {
        pull.obj = 2;
    }
    else
    if (k == D3)
    {
        pull.obj = 4;
    }
    else 
    if (k == D4)
    {
        pull.obj = 5;
    }
    else
    if (k == D5)
    {
        pull.obj = 6;
    }
    else
    if (k == D6)
    {
        pull.obj = 7;
    }
    else
    if (k == D7)
    {
        pull.obj = 3;
    }
    return pull;
}

float3 Normal(float3 z)
{
    vec3 z1 = z + vec3(EPS_DER, 0, 0);
    vec3 z2 = z - vec3(EPS_DER, 0, 0);
    vec3 z3 = z + vec3(0, EPS_DER, 0);
    vec3 z4 = z - vec3(0, EPS_DER, 0);
    vec3 z5 = z + vec3(0, 0, EPS_DER);
    vec3 z6 = z - vec3(0, 0, EPS_DER);
    float dx = Draw(z1).dist - Draw(z2).dist;
    float dy = Draw(z3).dist - Draw(z4).dist;
    float dz = Draw(z5).dist - Draw(z6).dist;
    return normalize(vec3(dx, dy, dz) / (2.0*EPS_DER));
}

HIT Hitting(RAY ray)
{
    float step = 0.0;
    HIT hit;
    hit.Ex = false;
    hit.obj = 0;
    vec3  eye;
    for( int k = 0; k < 200; k++)
    {
        eye = ray.p + ray.d*step;
        PULL pull = Draw(eye);
        float h = pull.dist;
        if( h < EPS_HIT)
        {
            hit.obj = pull.obj;
            hit.Ex = true;
            rid = step;            
            return hit;
        }
        step += h;
    }
    return hit;
}

bool Visible(vec3 position, vec3 sourse, int obj)
{
    vec3 stat = position - sourse;
    RAY ray;
    ray.p = sourse;
    ray.d = normalize(stat);
    HIT hit = Hitting(ray);
    if (obj == hit.obj)
    {
        return true;
    }
    return false; 
}

float distance(vec3 a, vec3 b)
{
    vec3 d = a - b;
    return length(d);
}

float3 Shade(RAY ray, vec3 position, OBJ obj, vec3 sourse_pos)
{
    vec3 N = Normal(position);
    vec3 Ds = normalize(sourse_pos - position);
    vec3 Dr = normalize(ray.p - position);
    float LdotN = max(0, dot(Ds,N));
    float diffuse = obj.mat_kd * LdotN;
    float D = distance(sourse_pos, position);
    float att = 1.0 /D /D  ;
    vec3 H = normalize(Ds + Dr);
    float RdotV = dot(H, Dr);
    float specular = 0.0;
    if((RdotV >= 0.0) && (LdotN >= 0.0))
    {
        specular = obj.mat_ks * pow(max(0, RdotV),obj.mat_shiness);
    }
    float light = att * diffuse + att * specular;
    return vec3(light,light,light);
}

vec3 SomeFog(vec3 rgb, float distance, vec3 rayDir, vec3 SunDir) 
{
    float b = 0.2;
    float fogAmount = 1.0 - exp(-distance*b);
    float sunAmount = max(dot(rayDir,SunDir), 0.0);
    vec3 fogColor  = mix( vec3(0.5,0.6,0.7), vec3(1.0,0.9,0.7), pow(sunAmount, 2.0));
    return mix( rgb, fogColor, fogAmount );
}

RAY Reflect(vec3 eyedir,vec3 point)
{
float3 normal = Normal(point);
float3 Dir = normalize(reflect(eyedir,normal)); 
RAY ray;
ray.p = Dir.x*normal.x + Dir.y*normal.y + Dir.z*normal.z < 0 ? point - normal*1e-3 : point + normal*1e-3;
ray.d = Dir;
return ray;
}

vec4 Trace(RAY ray)
{
    amb = float3(0.0,0.0,0.0); // global 
    float alpha = 1.0;
    float A = 1.0;
    vec3 help;
    int refl_dep;
    float3 int_color = vec3(0.0);
    for (int j=0; j < REFLECTION_DEP; j++) {
        HIT hit = Hitting(ray);
        if (!hit.Ex) {
            if (g_fog==1) 
                help = SomeFog(vec3(0.0,0.2,0.1) ,3.5, ray.p, ray.d);
            else
                help = vec3(0.0,0.2,0.1);
            return vec4(help, 0.0);
        }
        vec3 color = objects[hit.obj].color;
        vec3 hit_point = ray.p + ray.d*rid;
        for( int i = 0; i<NUM ; i++) {
            if(Visible(hit_point, light_s[i], hit.obj))
                color += Shade(ray,hit_point, objects[hit.obj],light_s[i]);
        }
        color += amb; // amb (ambient) - global
        int_color = A*color;

/*---------reflection for objects-------------------------------*/
/*--------------------------------------------------------------*/
        if (objects[hit.obj].reflection > 0.0 && g_reflection == 1) 
        {
            A *= objects[hit.obj].reflection;
            ray = Reflect(ray.d,hit_point);
        }
        else 
        {
            if (g_fog==1) color = SomeFog(color, 3.3, ray.p, ray.d);
            return vec4(color,alpha);
        }
    }
}

void main(void)
{	
    float w = float(512);
    float h = float(512);
    float x = fragmentTexCoord.x*w; 
    float y = fragmentTexCoord.y*h;
    RAY eye;
    eye.p = float3(0.0); 
    eye.d = EyeRayDir(x,y,w,h);
    eye.p = (g_rayMatrix*float4(eye.p,1)).xyz;
    eye.d = float3x3(g_rayMatrix)*eye.d;
    float4 color = Trace(eye);
	fragColor = clamp(color,0,1);
}
