#include <osgParticle/ConnectedParticleSystem>
#include <osgDB/ObjectWrapper>
#include <osgDB/InputStream>
#include <osgDB/OutputStream>

REGISTER_OBJECT_WRAPPER( osgParticleConnectedParticleSystem,
                         new osgParticle::ConnectedParticleSystem,
                         osgParticle::ConnectedParticleSystem,
                         "osg::Object osg::Node osg::Drawable osgParticle::ParticleSystem osgParticle::ConnectedParticleSystem" )
{
}
