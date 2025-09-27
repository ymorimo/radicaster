import { Template } from 'aws-cdk-lib/assertions';
import { App } from 'aws-cdk-lib';
import * as Deployment from '../lib/radicaster-stack';

test('Empty Stack', () => {
  // Set required environment variables for the test
  process.env.RADICASTER_S3_BUCKET = 'test-bucket';
  process.env.RADICASTER_BASIC_AUTH_USER = 'testuser';
  process.env.RADICASTER_BASIC_AUTH_PASSWORD = 'testpass';

  const app = new App();
  // WHEN
  const stack = new Deployment.RadicasterStack(app, 'MyTestStack', {
    env: { region: 'us-east-1' } // EdgeFunctions require explicit region
  });
  // THEN
  const template = Template.fromStack(stack);
  template.resourceCountIs('AWS::S3::Bucket', 1);
  template.resourceCountIs('AWS::CloudFront::Distribution', 1);
});
